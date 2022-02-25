;;; bgt.el --- Record and view blood glucose level  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Homepage: https://github.com/md-arif-shaikh/bgt
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1") (dash "2.19.1"))
;; Keywords: convenience, glucose monitoring

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

;;; Commentary:
;; This is simple package to help you keep your glucose level
;; with Emacs and export data to csv or even plot the data to see the trend.
;; Plotting would require python with pandas and matplotlib installed on your
;; machine.

;;; Code:

(require 'org)
(require 'dash)

(defcustom bgt-file-name "~/bgt.org"
  "Org file name to save the blood glucose data."
  :type 'string
  :group 'bgt)

(defcustom bgt-csv-file-name "~/bgt.csv"
  "CSV file name for exporting the table data from org file."
  :type 'string
  :group 'bgt)

(defcustom bgt-python-file "~/bgt.py"
  "Path to the python script for plotting."
  :type 'string
  :group 'bgt)

(defcustom bgt-python-path "~/miniconda/bin/python"
  "Path to python."
  :type 'string
  :group 'bgt)

(defcustom bgt-plot-file "~/bgt.pdf"
  "File name to save the plot."
  :type 'string
  :group 'bgt)


(defun bgt-create-initial-file ()
  "Create the data file with initial inputs when the file does not exist."
  (unless (string-equal "org" (file-name-extension bgt-file-name))
    (user-error "`bgt-file-name` should be an `org` file!"))
  (with-current-buffer (generate-new-buffer bgt-file-name)
    (insert "#+TITLE: Blood Glucose Table\n")
    (insert (format "#+AUTHOR: %s\n\n" user-full-name))
    (insert "* BGT\n")
    (insert ":PROPERTIES:\n")
    (insert (format ":TABLE_EXPORT_FILE: %s\n" bgt-csv-file-name))
    (insert ":TABLE_EXPORT_FORMAT: orgtbl-to-csv\n")
    (insert ":END:\n\n")
    (insert "#+TBLNAME: bgt\n")
    (insert "|--|--|--|--|--|\n")
    (insert "|Date |BG | Category | Test | Lab|\n")
    (insert "|--|--|--|--|--|\n")
    (write-file bgt-file-name)
    (kill-buffer (-last-item (split-string bgt-file-name "/"))))
  (message "Created initial file."))

(defun bgt--goto-table-begin (name)
  "Go to begining of table named NAME if point is not in any table."
  (unless (org-at-table-p)
    (let ((org-babel-results-keyword "NAME"))
      (org-babel-goto-named-result name)
      (forward-line 2)
      (goto-char (org-table-begin)))))

(defun bgt-get-lab-names (data-file)
  "Get the lab names for completion from the data in DATA-FILE.
DATA-FILE is the `org` file where the data of glucose levels are stored."
  (if (not (file-exists-p data-file))
      '()
    (let ((buff-name (concat (temporary-file-directory) "bgt-labs.org"))
	  (lab-names '()))
      (with-current-buffer (generate-new-buffer buff-name)
        (insert-buffer-substring (find-file-noselect data-file))
	(bgt--goto-table-begin "bgt")
	(forward-line 2)
	(while (org-at-table-p)
	  (push (string-trim (org-table-get-field 5)) lab-names)
          (forward-line))
	(kill-buffer buff-name)
	(kill-buffer (-last-item (split-string data-file "/")))
	(delete-file buff-name)
	(delete-dups lab-names)))))

(defun bgt-add-entry ()
  "Add entry to blood glucose table."
  (interactive)
  (let* ((date (org-read-date 'with-time nil nil "Date and time: "))
	 (bg-level (read-number "Glucose level: "))
	 (bg-category (completing-read "Test category: " '("Fasting" "Random" "Post-prandial" "HbA1c" "Mean-Blood-Glucose")))
	 (bg-sample (completing-read "Blood sample: " '("Plasma" "Capillary")))
	 (bg-lab (completing-read "Lab name: " (bgt-get-lab-names bgt-file-name))))
    (unless (file-exists-p bgt-file-name)
      (bgt-create-initial-file))
    (with-temp-buffer
      (insert (format "|%s |%.1f |%s |%s |%s |\n" date bg-level bg-category bg-sample bg-lab))
      (append-to-file (point-min) (point-max) bgt-file-name))
    (when (string-equal (completing-read "Add another expense: " '("no" "yes")) "yes")
      (bgt-add-entry))
    (with-current-buffer (find-file-noselect bgt-file-name)
      (goto-char (point-max))
      (forward-line -1)
      (org-table-align)
      (write-file bgt-file-name))))

(defun bgt-view-entry ()
  "View the glucose table."
  (interactive)
  (find-file-other-window bgt-file-name))

(defun bgt-export-to-csv ()
  "Export bgt data to a csv file."
  (interactive)
  (with-current-buffer (find-file-noselect bgt-file-name)
    (goto-char (point-max))
    (forward-line -2)
    (org-table-export)))

(defun bgt-plot (start-date end-date)
  "Plot BG data from START-DATE to END-DATE."
  (interactive
   (list (org-read-date nil nil nil "Start Date: ")
	 (org-read-date nil nil nil "End Date: ")))
  (bgt-export-to-csv)
  (unless bgt-python-file
    (user-error "`bgt-python-file` can not be nil.  'setq bgt-python-file'!"))
  (unless bgt-plot-file
    (setq bgt-plot-file (concat (temporary-file-directory) "bgt.pdf")))
  (when (file-exists-p bgt-plot-file)
    (delete-file bgt-plot-file))
  (if (file-exists-p bgt-python-file)
      (shell-command (format "%s %s --data_file %s --plot_file %s --start_date %s --end_date %s"
			     (or bgt-python-path "python") bgt-python-file bgt-csv-file-name bgt-plot-file start-date end-date))
    (message "python file not found. Set the python file path with 'setq bgt-python-file'."))
  (when (file-exists-p bgt-plot-file)
    (find-file-other-window bgt-plot-file)))

(provide 'bgt)
;;; bgt.el ends here
