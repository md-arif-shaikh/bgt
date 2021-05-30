;;; bgt.el --- record blood glucose level with emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary: This is simple package to help you keep your glucose level
;; with emacs and export data to csv or even plot the data to see the trend.
;; Plotting would require python with pandas and matplotlib installed on your
;; machine.

;;; Code:

(require 'org)

(defcustom bgt-file-name "/tmp/bgt.org"
  "Org file name to save the blood glucose data."
  :type 'string
  :group 'bgt
  )

(defcustom bgt-csv-file-name "/tmp/bgt.csv"
  "CSV file name for exporting the table data from org file."
  :type 'string
  :group 'bgt)

(defcustom bgt-python-file "~/.emacs.d/bgt.py"
  "Path to the python script for plotting."
  :type 'string
  :group 'bgt)

(defun bgt-add-entry ()
  "Add bg record."
  (interactive)
  (let ((file-name bgt-file-name)
	(date-time (org-read-date 'with-time nil nil "Record time:  "))
	(bg-level (read-string "BG level: "))
	(bg-category (completing-read "Record type: " '("Fasting" "Random" "Post-prandial")))
	(bg-test (completing-read "Test type: " '("Plasma" "Capillary")))
	(bg-lab (completing-read "Lab Name: " '("Glucometer"))))
    (with-temp-buffer
      (when (not (file-exists-p file-name))
	;;(set-buffer (generate-new-buffer file-name))
	(insert "#+TITLE: Blood Glucose Table\n\n")
	(insert "* BGT\n")
	(insert ":PROPERTIES:\n")
	(insert (format ":TABLE_EXPORT_FILE: %s\n" bgt-csv-file-name))
	(insert ":TABLE_EXPORT_FORMAT: orgtbl-to-csv\n")
	(insert ":END:\n\n")
	(insert "|--|--|--|--|--|\n")
	(insert "|Date |BG | Category | Test | Lab|\n")
	(insert "|--|--|--|--|--|\n")
	(append-to-file (point-min) (point-max) file-name)))
    (with-temp-buffer
      (insert (format "|%s |%s |%s |%s |%s |\n" date-time bg-level bg-category bg-test bg-lab))
      (insert "|--|--|--|--|--|\n")
      (append-to-file (point-min) (point-max) file-name))
    (with-temp-buffer
      (switch-to-buffer (find-file-noselect file-name))
      (goto-char (point-max))
      (forward-line -1)
      (org-table-align)
      (write-file file-name))))

(defun bgt-export-to-csv ()
  "Export bgt data to a csv file."
  (interactive)
  (let ((file-name bgt-file-name))
    (with-temp-buffer
      (switch-to-buffer (find-file-noselect file-name))
      (goto-char (point-max))
      (forward-line -2)
      (org-table-export))))

(defun bgt-plot ()
  "Plot BG data."
  (interactive)
  (let ((bgt-data-file-name bgt-csv-file-name))
    (bgt-export-to-csv)
    (cond ((file-exists-p bgt-python-file)
	   (shell-command (format "python %s --data_file %s" bgt-python-file bgt-data-file-name))
	   (find-file-other-frame "/tmp/bgt.pdf"))
	  (t (message "python file not found. Set the python file path with 'setq bgt-python-file'.")))))

(provide 'bgt)
;;; bgt.el ends here
