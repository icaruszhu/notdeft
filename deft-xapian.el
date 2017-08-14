(defcustom deft-xapian-program nil
  "Xapian backend's executable program path.
When nil, incremental search is limited to
the files in the current `deft-directory'."
  :type 'string
  :safe 'stringp
  :group 'deft)

(defcustom deft-xapian-max-results 100
  "Maximum number of Xapian query results.
\(I.e., '--max-count' for `deft-xapian-program'.)
No limit if nil."
  :type 'integer
  :group 'deft)

(defcustom deft-xapian-language "en"
  "Stemming language to use in Xapian indexing and searching."
  :type 'string
  :safe 'stringp
  :group 'deft)

(defun deft-xapian-index-dirs (dirs &optional async)
  "Create or update a Xapian index for DIRS.
Report any errors in a separate buffer.
With ASYNC, do the indexing asynchronously."
  (shell-command
   (concat
    (shell-quote-argument deft-xapian-program) " index"
    " --chdir ~"
    " --extension " (shell-quote-argument (concat "." deft-extension))
    " --lang " (shell-quote-argument deft-xapian-language)
    " " (mapconcat
	 (lambda (dir)
	   (shell-quote-argument
	    (file-relative-name dir "~")))
	 dirs " ")
    (if async " &" ""))
   nil "*Deft indexing errors*"))

(defun deft-xapian-search (dirs &optional query)
  "Perform the Xapian QUERY on the indexes in DIRS.
I.e., perform the query in terms of the Xapian indexes
in the specified DIRS. Where a query is not specified,
use a query that matches any file.
Return at most `deft-xapian-max-results' results, as
pathnames of the matching files. Sort the results
based on file modification time, most recent first."
  (let ((s (shell-command-to-string
	    (concat
	     (shell-quote-argument deft-xapian-program) " search --time-sort"
	     " --lang " (shell-quote-argument deft-xapian-language)
	     (if deft-xapian-max-results
		 (format " --max-count %d" deft-xapian-max-results)
	       "")
	     (if query
		 (concat " --query " (shell-quote-argument query))
	       "")
	     " " (mapconcat
		  (lambda (dir)
		    (shell-quote-argument
		     (expand-file-name dir "~")))
		  dirs " ")))))
    (mapcar
     (lambda (file)
       (expand-file-name file "~"))
     (split-string s "\n" t))))

(provide 'deft-xapian)
