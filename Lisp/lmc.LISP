;;;; -*- Mode: Lisp -*-
;;;; lmc.lisp --

;;;-----------------------------------------------------------------------------

;;; Funzioni del LMC

;;; incrementa-pc --

(defun incrementa-pc (old-pc) 
  (cond ((< old-pc 99) (+ 1 old-pc))
        ((= old-pc 99) 0)))


;;; xx --

(defun xx (istr) 
  (mod istr 100))


;;; istruzione --

(defun istruzione (mem pc) 
  (nth pc mem)) 


;;; add --

(defun add (val acc) 
  (mod (+ val acc) 1000))


;;; add-flag --

(defun add-flag (val acc) 
  (cond ((>= (+ val acc) 1000) 'flag)
        ((< (+ val acc) 1000) 'noflag)))


;;; sub --

(defun sub (val acc) 
  (mod (- acc val) 1000))


;;; sub-flag --

(defun sub-flag (val acc)
  (cond ((< (- acc val) 0) 'flag)
        ((>= (- acc val) 0) 'noflag)))


;;; store --

(defun store (mem pc acc)
  (substitute acc (nth (xx (istruzione mem pc)) mem) mem 
           :start (xx (istruzione mem pc)) 
           :end (+ 1 (xx (istruzione mem pc)))))


;;; one-instruction --

(defun one-instruction (stato)
  (let ((acc (nth 2 stato))
	(pc (nth 4 stato))
        (mem (nth 6 stato))
        (in (nth 8 stato))
        (out (nth 10 stato))
        (flag (nth 12 stato)))
   
    (cond ((and (>= (istruzione mem pc) 100) ;; add
		(< (istruzione mem pc) 200))
	   (list 'state :acc (add (nth (xx (istruzione mem pc)) mem) acc)
	                :pc (incrementa-pc pc)
			:mem mem
			:in in
			:out out
			:flag (add-flag (nth (xx (istruzione mem pc)) mem)
					acc)))

	  ((and (>= (istruzione mem pc) 200) ;; sub
		(< (istruzione mem pc) 300))
	   (list 'state :acc (sub (nth (xx (istruzione mem pc)) mem) acc)
		        :pc (incrementa-pc pc)
			:mem mem
			:in in
			:out out
			:flag (sub-flag (nth (xx (istruzione mem pc)) mem)
					acc))) 

	  ((and (>= (istruzione mem pc) 300) ;; sta
		(< (istruzione mem pc) 400))
	   (list 'state :acc acc
	                :pc (incrementa-pc pc)
			:mem (store mem pc acc)
			:in in
			:out out
			:flag flag)) 

	  ((and (>= (istruzione mem pc) 500) ;; lda
		(< (istruzione mem pc) 600))
	   (list 'state :acc (nth (xx (istruzione mem pc)) mem)
		        :pc (incrementa-pc pc)
			:mem mem
			:in in
			:out out
			:flag flag)) 

	  ((and (>= (istruzione mem pc) 600) ;; bra
		(< (istruzione mem pc) 700))
	   (list 'state :acc acc
		        :pc (xx (istruzione mem pc))
			:mem mem
			:in in
			:out out
			:flag flag)) 

	  ((and (>= (istruzione mem pc) 700) ;;brz con acc = 0
		(< (istruzione mem pc) 800)
		(= acc 0)
		(equalp flag 'noflag))
	   (list 'state :acc acc
		        :pc (xx (istruzione mem pc))
			:mem mem
			:in in
			:out out
			:flag flag)) 
          
          ((and (>= (istruzione mem pc) 700) ;;brz con acc \= 0
		(< (istruzione mem pc) 800)
		(or (not (= acc 0))
                    (not (equalp flag 'noflag))))
	   (list 'state :acc acc
		        :pc (incrementa-pc pc)
			:mem mem
			:in in
			:out out
			:flag flag))  

	  ((and (>= (istruzione mem pc) 800) ;;brp con flag assente
		(< (istruzione mem pc) 900)
		(equalp flag 'noflag))
	   (list 'state :acc acc
		        :pc (xx (istruzione mem pc))
			:mem mem
			:in in
			:out out
			:flag flag)) 

          ((and (>= (istruzione mem pc) 800) ;;brp con flag presente
		(< (istruzione mem pc) 900)
		(equalp flag 'flag))
	   (list 'state :acc acc
		        :pc (incrementa-pc pc)
			:mem mem
			:in in
			:out out
			:flag flag)) 

	  ((and (= (istruzione mem pc) 901) ;; in
                (not (equalp in 'nil)))
	   (list 'state :acc (nth 0 in)
	      	        :pc (incrementa-pc pc)
			:mem mem
			:in (rest in)
			:out out
			:flag flag))
          
          ((and (= (istruzione mem pc) 901) ;; in con lista vuota
                (equalp in 'nil))
	   (print "Tentativo di accedere alla lista di input vuota")
           (abort))

	  ((= (istruzione mem pc) 902) ;; out
	   (list 'state :acc acc
		        :pc (incrementa-pc pc)
			:mem mem
			:in in
			:out (append out (list acc))
			:flag flag)) 

	  ((and (>= (istruzione mem pc) 0) ;; htl
		(< (istruzione mem pc) 100))
	   (list 'halted-state :acc acc
		               :pc pc
			       :mem mem
			       :in in
			       :out out
			       :flag flag)) 
          
          ((or (> (istruzione mem pc) 902) ;; illegal instruction
	       (and (>= (istruzione mem pc) 400)
		    (< (istruzione mem pc) 500)))
	   'illegal-instruction))))	  


;;; execution-loop --

(defun execution-loop (stato)
  (if (equalp (nth 0 stato) 'halted-state)
      (nth 10 stato)
    (let ((new-state (one-instruction stato)))
      (if (eq new-state 'illegal-instruction)
          "Illegal instruction"
        (execution-loop new-state)))))

;;;-----------------------------------------------------------------------------

;;; Funzioni dell'interprete

;;; controllo-errori --

(defun controllo-errori (mem)
  (when mem
    (let* ((stringa (car mem)) 
           (posizione (search "/" stringa))) 
      (if (not (equal posizione 'nil)) 
          (if (equal (subseq stringa posizione (+ 1 posizione)) 
                     (subseq stringa (+ 1 posizione) (+ 2  posizione)))
              (if (not (cdr mem)) 
                  T
                (controllo-errori (cdr mem)))
            nil) 
        (if (not (cdr mem)) 
            T
          (controllo-errori (cdr mem)))))))


;;; eliminazione-commenti --

(defun eliminazione-commenti (mem)
  (when mem
    (if (equal (car (split-sequence "//" (car mem))) "")
        (eliminazione-commenti (cdr mem))
      (append (list (car (split-sequence "//" (car mem))))
	      (eliminazione-commenti (cdr mem))))))


;;; eliminazione-spazi --

(defun eliminazione-spazi (mem)
  (when mem
    (let* ((lista (split-sequence " " (car mem)))
           (lista (remove-if (lambda (e) (equal "" e)) lista))
           (lista (list lista)))
      (append lista (eliminazione-spazi (cdr mem))))))


;;; controllo-parole --

(defun controllo-parole (lista index)
  (if (and (not (equal (car lista) "add"))
	   (not (equal (car lista) "sub"))
	   (not (equal (car lista) "sta"))
	   (not (equal (car lista) "lda"))
	   (not (equal (car lista) "bra"))
	   (not (equal (car lista) "brz"))
	   (not (equal (car lista) "brp"))
	   (not (equal (car lista) "inp"))
	   (not (equal (car lista) "out"))
	   (not (equal (car lista) "dat"))
	   (not (equal (car lista) "hlt")))
      (list (car lista) index)))


;;; creazione-etichette --

(defun  creazione-etichette (mem index)
  (when mem
    (let ((lista-parole (remove-if (lambda (e) (equal "" e))
				   (split-sequence " " (car mem)))))
      (if (> (list-length lista-parole) 1)
          (append (controllo-parole lista-parole index)
		  (creazione-etichette (cdr mem) (+ 1 index)))
        (creazione-etichette (cdr mem) (+ 1 index)))
      )))


;;; trova-valore-etichetta --

(defun trova-valore-etichetta (etichetta lista)
  (when lista
    (if (equalp etichetta (car lista))
        (cadr lista)
      (trova-valore-etichetta etichetta (cddr lista)))))


;;; contiene-etichetta --

(defun contiene-etichetta (stringa)
  (let ((carattere (subseq stringa 0 1)))
    (if (or (equalp carattere "0")
	    (equalp carattere "1")
	    (equalp carattere "2")
	    (equalp carattere "3")
	    (equalp carattere "4")
	    (equalp carattere "5")
	    (equalp carattere "6")
	    (equalp carattere "7")
	    (equalp carattere "8")
	    (equalp carattere "9"))
	nil
      T)))


;;; sostituzione-etichette-2 --

(defun sostituzione-etichette-2 (istruzione lista)
  (cond ((or (equalp (cadr istruzione) "dat")
	    (equalp (cadr istruzione) "hlt")
	    (equalp (cadr istruzione) "inp")
	    (equalp (cadr istruzione) "out"))
	 (list (cadr istruzione)))
        ((and (equalp (car istruzione) "dat")
              (not (contiene-etichetta (cadr istruzione))))
	 istruzione)
	((and (or (equalp (car istruzione) "add")
		 (equalp (car istruzione) "sub")
		 (equalp (car istruzione) "sta")
		 (equalp (car istruzione) "lda")
		 (equalp (car istruzione) "bra")
		 (equalp (car istruzione) "brz")
		 (equalp (car istruzione) "brp"))
	     (contiene-etichetta (cadr istruzione)))
	 (list (car istruzione) (write-to-string (trova-valore-etichetta
						  (cadr istruzione) lista))))

	((and (or (equalp (car istruzione) "add")
		 (equalp (car istruzione) "sub")
		 (equalp (car istruzione) "sta")
		 (equalp (car istruzione) "lda")
		 (equalp (car istruzione) "bra")
		 (equalp (car istruzione) "brz")
		 (equalp (car istruzione) "brp"))
	     (not (contiene-etichetta (cadr istruzione))))
	 (list (car istruzione) (cadr istruzione)))
	(T (print "Errore file assembly")
	   (abort))))


;;; sostituzione-etichette-3 --

(defun sostituzione-etichette-3 (istruzione lista)
  (cond ((and (equalp (cadr istruzione) "dat")
	      (not (contiene-etichetta (caddr istruzione))))
	 (list "dat" (caddr istruzione)))
	((and (or (equalp (cadr istruzione) "add")
		 (equalp (cadr istruzione) "sub")
		 (equalp (cadr istruzione) "sta")
		 (equalp (cadr istruzione) "lda")
		 (equalp (cadr istruzione) "bra")
		 (equalp (cadr istruzione) "brz")
		 (equalp (cadr istruzione) "brp"))
	     (contiene-etichetta (caddr istruzione)))
	 (list (cadr istruzione) (write-to-string (trova-valore-etichetta
						   (caddr istruzione) lista))))
	((and (or (equalp (cadr istruzione) "add")
		 (equalp (cadr istruzione) "sub")
		 (equalp (cadr istruzione) "sta")
		 (equalp (cadr istruzione) "lda")
		 (equalp (cadr istruzione) "bra")
		 (equalp (cadr istruzione) "brz")
		 (equalp (cadr istruzione) "brp"))
	     (not (contiene-etichetta (caddr istruzione))))
	 (list (cadr istruzione) (caddr istruzione)))
	(T (print "Errore file assembly")
	   (abort))))


;;; sostituzione-etichette --

(defun sostituzione-etichette (mem lista-etichette)
  (when mem
    (cond ((= (list-length (car mem)) 1)
	   (append (list (car mem)) (sostituzione-etichette
				     (cdr mem) lista-etichette)))
	  ((= (list-length (car mem)) 2) 
	   (append (list (sostituzione-etichette-2 (car mem) lista-etichette))
		   (sostituzione-etichette (cdr mem) lista-etichette)))
	  ((= (list-length (car mem)) 3) 
	   (append (list (sostituzione-etichette-3 (car mem) lista-etichette))
		   (sostituzione-etichette (cdr mem) lista-etichette))))))


;;; istruzione-lunghezza-1 --

(defun istruzione-lunghezza-1 (istruzione)
  (cond ((equalp (car istruzione) "dat")
	 (list 0))
	((equalp (car istruzione) "hlt")
	 (list 0))
	((equalp (car istruzione) "inp")
	 (list 901))
	((equalp (car istruzione) "out")
	 (list 902))
	(T (print "Errore file assembly")
	   (abort))))


;;; istruzione-lunghezza-2 --

(defun istruzione-lunghezza-2 (istruzione)
  (cond ((< (parse-integer (cadr istruzione)) 100)
	 (cond ((equalp (car istruzione) "add")
		(list (+ 100 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "sub")
		(list (+ 200 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "sta")
		(list (+ 300 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "lda")
		(list (+ 500 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "bra")
		(list (+ 600 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "brz")
		(list (+ 700 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "brp")
		(list (+ 800 (parse-integer (cadr istruzione)))))
	       ((equalp (car istruzione) "dat")
		(list (parse-integer (cadr istruzione))))))
	((and (equalp (car istruzione) "dat")
              (< (parse-integer (cadr istruzione)) 1000))
	 (list (parse-integer (cadr istruzione))))
	(T (print "Errore file assembly")
	   (abort))))


;;; riempimento-memoria --

(defun riempimento-memoria (indice)
  (if (< indice 100)
      (append (list 0) (riempimento-memoria (+ 1 indice)))))


;;; creazione-istruzioni --

(defun creazione-istruzioni (mem)
  (when mem
    (cond ((=(list-length (car mem)) 1)
	   (append (istruzione-lunghezza-1 (car mem)) (creazione-istruzioni
						       (cdr mem))))
	  ((=(list-length (car mem)) 2)
	   (append (istruzione-lunghezza-2 (car mem)) (creazione-istruzioni
						       (cdr mem))))
	  (T (print "Errore file assembly")
	     (abort)))))


;;; read-list-from --

(defun read-list-from (input-stream)  
  (let ((e (read-line input-stream nil 'eof)))
    (unless (eq e 'eof)
      (let ((lista (list e)))
        (append lista (read-list-from input-stream))))))


;;; lmc-load --

(defun lmc-load (filename)
  (let* ((mem (with-open-file (in filename
			       :direction :input
			       :if-does-not-exist :error)
			      (read-list-from in)))
	 (check (controllo-errori mem)))
    (if (not check) (print "File contenente errori"))
    (let* ((mem (eliminazione-commenti mem))
           (lista-etichette (creazione-etichette mem 0))
           (mem (eliminazione-spazi mem))
           (mem (sostituzione-etichette mem lista-etichette))
           (mem (creazione-istruzioni mem)))
      (cond ((> (list-length mem) 100)
	     "Memoria troppo lunga"
	     (abort))
	    (T (let ((mem (append mem (riempimento-memoria (list-length mem)))))
      mem))))))


;;; lmc-run --

(defun lmc-run (filename in)
    (let* ((mem (lmc-load filename))
	   (out (execution-loop (list 'state
				      :acc 0
				      :pc 0
				      :mem mem
				      :in in
				      :out (list )
				      :flag 'noflag))))
      out))

