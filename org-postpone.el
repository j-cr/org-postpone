;;; org-postpone.el --- Postpone tasks in agenda buffers -*- lexical-binding: t -*-

;; URL: https://github.com/j-cr/org-postpone
;; Keywords: org, outlines, hypermedia, calendar, wp
;; Version: 1.0

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package allows you to postpone a scheduled entry, hiding it from the
;; agenda buffer for today.  It is especially useful for habits (see chapter
;; "5.3.3 Tracking your habits" in the org manual).
;;
;; To use it, you have to customize your `org-agenda-custom-commands' by adding
;; this line to the list of settings of your custom command for today's agenda:
;;   (org-agenda-skip-function '(org-postpone-skip-if-postponed))
;; See the docstring of `org-postpone-skip-if-postponed' for details.  Once you've
;; done that, you can call `org-postpone-entry-until-tomorrow' (bound to 'k' by
;; default) from the agenda buffer to hide the entry at the point.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

(require 'org)
(require 'org-agenda)

(eval-when-compile
  (require 'cl))


(defun org-postpone--is-entry-postponed-today ()
  "Internal.
Is the property POSTPONED contains the today's date in the entry at point?"
  (let ((postponed (org-entry-get (point) "POSTPONED")))
    (when postponed
      (equal (org-time-today)
             (org-time-string-to-seconds postponed)))))


(defun org-postpone-skip-if-postponed ()
  "Skip current entry if it's been postponed.

Returns nil if the entry shouldn't be skipped; returns the
position of the next heading if the entry is postponed today
\(see `org-agenda-skip-if' and `org-agenda-skip-function' for
details).

To use it, add something like this to `org-agenda-custom-commands':

\(\"x\" \"My agenda for today\"
 ((agenda \"\" ((org-agenda-ndays 1))))
 ((org-agenda-skip-function '(org-postpone-skip-if-postponed)) ; <-- add this
  ;; maybe more options here...
  ))"
  (let (beg end)
    (org-back-to-heading t)
    (setq beg (point)
          end (progn (outline-next-heading) (1- (point))))
    (goto-char beg)
    (when (org-postpone--is-entry-postponed-today)
      end)))


(defun org-postpone--set-postponed ()
  "Internal.
Set the :POSTPONED: property to the current date for
the agenda entry at point; adapted from `org-agenda-set-property'."
  (org-agenda-check-no-diary)
  (let* ((hdmarker (or (org-get-at-bol 'org-hd-marker)
                       (org-agenda-error)))
         (buffer (marker-buffer hdmarker))
         (pos (marker-position hdmarker))
         (inhibit-read-only t)
         ;; newhead
         )
    (org-with-remote-undo buffer
      (with-current-buffer buffer
        (widen)
        (goto-char pos)
        (save-excursion
          (org-show-context 'agenda))
        (save-excursion
          (and (outline-next-heading)
               (org-flag-heading nil)))   ; show the next heading
        (goto-char pos)
        ;; only this line is changed compared to org-agenda-set-property:
        (org-set-property "POSTPONED"
                          (with-temp-buffer
                            (org-insert-time-stamp (org-time-today)
                                                   nil t)))))))


(defun org-postpone-entry-until-tomorrow ()
  "Hide the scheduled entry from the agenda for today.
Note that this will not affect the scheduling: the entry will be shown
again tomorrow.  See also: `org-postpone-skip-if-postponed'"
  (interactive)
  (org-agenda-check-type t 'agenda)

  (org-postpone--set-postponed)

  (org-agenda-redo)
  (org-agenda-set-mode-name)
  (message "Task postponed until tomorrow"))


(org-defkey org-agenda-mode-map "k" 'org-postpone-entry-until-tomorrow)

(provide 'org-postpone)

;;; org-postpone.el ends here
