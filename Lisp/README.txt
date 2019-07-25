lmc.LISP implementa:
- Un simulatore del LMC che dato il contenuto iniziale delle memoria (una lista di 100 numeri)
e una sequenza di valori di input simuli il comportamento del LMC e produca il contenuto
della coda di output dopo l’arresto del LMC;
- Un assembler che, dato un file scritto nell’assembly semplificato del LMC produca il
contenuto iniziale della memoria.


Come utilizzare lmc.LISP:
Inserire nel prompt di LispWorks "(lmc-run filename input)", dove:
filename è l'indirizzo del file assembly che verrà elaborato;
input è una lista di interi.

Esempio: CL-USER 1 > (lmc-run "C:\\Users\\User\\Desktop\\factorial.lmc" '(5))
         120

---------------------------------------------------------------------------------------------------------------------------------------

Funzioni assembler: 

controllo-errori mem => boolean		controlla se vi sono errori di sintassi nel file assembly

eliminazione-commenti mem => new-mem

eliminazione-spazi mem => new-mem 

controllo-parole lista index => etichetta 	crea la singola etichetta

creazione-etichette mem index => lista-etichette	richiama controllo-parole e crea la lista di etichette 

trova-valore-etichette etichetta lista => val-etichetta		

contiene-etichetta stringa => boolean 

sostituzione-etichette-2 istruzione lista => new-istruzione	sostituisce eventuali etichette con il corrispettivo
								valore numerico e rimuove le etichette prima dell'istruzione

sostituzione-etichette-3 istruzione lista => new-istruzione	sostituisce eventuali etichette con il corrispettivo
								valore numerico e rimuove le etichette prima dell'istruzione

sostituzione-etichette mem lista-etichette => new-mem		richiama sostituzione-etichette-2 o sostituzione-etichette-3

istruzione-lunghezza-1 istruzione => num-istruzione		converte il codice assembly in codice macchina e 
								segnala eventuali errori

istruzione-lunghezza-2 istruzione => num-istruzione		converte il codice assembly in codice macchina e 
								segnala eventuali errori

riempimento-memoria n => lista		n è 100 - la lunghezza della memoria generata; crea una lista di n elemennti
					contenente soli 0 	

creazione-istruzioni mem => new-mem	richiama istruzione-lunghezza-1 o istruzione-lunghezza-2

read-list-from input-stream => lista-istruzioni		legge le istruzioni dal file assembly e le salva in una lista di stringhe

lmc-load filename => mem	richiama read-list-from, controllo-errori, eliminazione-commenti, creazione-etichette, 
				eliminazione-spazi, sostituzione-etichette, creazione-istruzioni. Controlla se la lunghezza
				della memoria è > 100 celle: se sì, interrompe l'esecuzione, altrimenti richiama riempimento-memoria

lmc-run filename in => out 	richiama lmc-load e execution-loop. out può rappresentare la lista di output o 
				"Illegal instruction"

---------------------------------------------------------------------------------------------------------------------------------------

Funzioni simulatore LMC:

incrementa-pc old-pc => new-pc

xx istr => xx

istruzione mem pc => istr

add val acc => accumulatore

add-flag val acc => flag 

sub val acc => accumulatore 

sub-flag val acc => flag

store mem pc acc => new-mem	sostituisce all'interno della cella di memoria alla posizione pc il valore
				dell'accumulatore.

one-instruction state => new-state	new-state è una lista della forma 
					(list stato :acc a
	               				    :pc b
						    :mem c
						    :in d
					 	    :out e
					     	    :flag f)
					dove
					a è un intero
					b è un intero
					c è una lista
					d è una lista
					e è una lista
					f è un simbolo che può essere 'flag o 'noflag
					stato è un simbolo che può essere 'state o 'halted-state.					

					Viene dapprima richiamata la funzione istruzione; in base ai valori che
					essa assume, vengono richiamate differenti funzioni.
					In caso di istruzione non valida, viene restituito 'illegal-instruction.
			
execution-loop state => new-state	controlla se state è un halted-state, se sì restituisce la lista di output,
					altrimenti controlla se è stata eseguita un'istruzione invalida, se sì stampa
					a video "Illegal instruction", altrimenti esegue ricorsivamente se stessa.

