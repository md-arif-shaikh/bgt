;;; bgt.el --- Record and view blood glucose level  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Md Arif Shaikh

;; Author: Md Arif Shaikh <arifshaikh.astro@gmail.com>
;; Homepage: https://github.com/md-arif-shaikh/bgt
;; Version: 0.0.1
;; Package-Requires: ((emacs "26.1"))
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

(defcustom bgt-file-name nil
  "Org file name to save the blood glucose data."
  :type 'string
  :group 'bgt)

(defcustom bgt-csv-file-name nil
  "CSV file name for exporting the table data from org file."
  :type 'string
  :group 'bgt)

(defcustom bgt-python-file nil
  "Path to the python script for plotting."
  :type 'string
  :group 'bgt)

(defcustom bgt-python-path nil
  "Path to python."
  :type 'string
  :group 'bgt)

(defcustom bgt-plot-file nil
  "File name to save the plot."
  :type 'string
  :group 'bgt)


(defun bgt-create-initial-file ()
  "Create the data file with initial inputs when the file does not exist."
  (unless bgt-file-name
    (error "`bgt-file-name` can not be nil.  Set it using `(setq bgt-file-name '/path-to-file/filename.org')`!"))
  (unless (string-equal "org" (file-name-extension bgt-file-name))
    (error "`bgt-file-name` should be an `org` file!"))
  (unless bgt-csv-file-name
    (error "`bgt-csv-file-name` can not be nil.  Set it using `(setq bgt-csv-file-name '/path-to-file/filename.csv')`!"))
  (with-current-buffer (generate-new-buffer bgt-file-name)
    (insert "#+TITLE: Blood Glucose Table\n\n")
    (insert "* BGT\n")
    (insert ":PROPERTIES:\n")
    (insert (format ":TABLE_EXPORT_FILE: %s\n" bgt-csv-file-name))
    (insert ":TABLE_EXPORT_FORMAT: orgtbl-to-csv\n")
    (insert ":END:\n\n")
    (insert "|--|--|--|--|--|\n")
    (insert "|Date |BG | Category | Test | Lab|\n")
    (insert "|--|--|--|--|--|\n")
    (write-file bgt-file-name)))

(defun bgt-add-entry ()
  "Add bg record."
  (interactive)
  (let ((date-time (org-read-date 'with-time nil nil "Record time:  "))
	(bg-level (read-string "BG level: "))
	(bg-category (completing-read "Record type: " '("Fasting" "Random" "Post-prandial")))
	(bg-test (completing-read "Test type: " '("Plasma" "Capillary")))
	(bg-lab (completing-read "Lab Name: " '("Glucometer"))))
    (unless (file-exists-p bgt-file-name)
      (bgt-create-initial-file))
    (with-temp-buffer
      (insert (format "|%s |%s |%s |%s |%s |\n" date-time bg-level bg-category bg-test bg-lab))
      (append-to-file (point-min) (point-max) bgt-file-name)
      (switch-to-buffer (find-file-noselect bgt-file-name))
      (goto-char (point-max))
      (forward-line -1)
      (org-table-align)
      (write-file bgt-file-name))))

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
    (error "`bgt-python-file` can not be nil.  'setq bgt-python-file'!"))
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
