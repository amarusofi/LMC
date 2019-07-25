lmc.pl implementa:
- Un simulatore del LMC che dato il contenuto iniziale delle memoria (una lista di 100 numeri)
e una sequenza di valori di input simuli il comportamento del LMC e produca il contenuto
della coda di output dopo l’arresto del LMC;
- Un assembler che, dato un file scritto nell’assembly semplificato del LMC produca il
contenuto iniziale della memoria.


Come utilizzare lmc.pl:
Inserire nel prompt di SWI-Prolog "lmc_run(Filename, Inp, Out).", dove:
Filename è l'indirizzo del file assembly che verrà elaborato;
Inp è una lista di interi;
Out è un simbolo a cui verrà associato l'output del programma.

Esempio: ?- lmc_run("C:\\Users\\User\\Desktop\\factorial.lmc", [5], Out).
         Out = [120].

-------------------------------------------------------------------------------------------------------------------------------------

Predicati assembler: 

lmc_load(+Filename, -Mem)	apre Filename, lo analizza tramite i predicati errore_file/2, 
				rimuovi_commento/2, ricerca_etichette/2, sostituzione_etichette/2
				e riempie la memoria con il predicato popola_memoria/2. Se Filename
				presenta un errore, lmc_load/2 termina l'esecuzione del programma.

lmc_run(+Filename, +In, -Out)	richiama lmc_load/2 e execution_loop/2.

slash_presente(+ListaDiCaratteri, -Boolean)	restituisce true se in ListaDiCaratteri è presente
						almeno un carattere '/', altrimenti restituisce false. 

commento_al_num(+Stringa, -N)	converte Stringa in una lista di caratteri che passa al predicato
				slash_presente/2. 
				Se slash_presente/2 restituisce false, allora nella stringa
				non vi è nè un errore di sintassi nè un commento, e commento_al_num/2
				restituisce -2.
				Se slash_presente/2 restituisce true, commento_al_num/2 controlla se vi 
				sono due '/' consecutivi: se sì, il predicato restituisce un numero >=0
				che corrisponde all'inizio del commento, altrimenti restituisce -1 ad
				indicare la presenza nel file di testo di un errore di sintassi. 

rimuovi_commento(+Lista1, -Lista2)	Lista1 è una lista di stringhe (le righe del file assembly).
					Lista2 è la lista di righe private dell'eventuale commento.
					Richiama il predicato commento_al_num/2.

errore_stringa(+Stringa, -Boolean) 	Esplicita la presenza di un errore di sintassi rilevato dal
					predicato commento_al_num/2. 

errore_file(+ListaDiStringhe, -Boolean)		ListaDiStringhe è la lista delle righe (l'intero file assembly). Il predicato
						restituisce true se nel file è presente almeno un errore di sintassi,
						altrimenti restituisce false. Usa errore_stringa/2.

creazione_etichetta(+NomeEtichetta, +Num)	amplia la base delle conoscenze, inserendo il fatto
						etichetta(NomeEtichetta, Num)

creazione_istruzioni(ListaDiStringhe, Val)	ListaDiStringhe contiene le singole parole che compongono una riga di istruzione.
						Converte il codice assembly in codice macchina.

riempimento_memoria(+N, -Lista)		N è la lunghezza della memoria generata.
					Restituisce una lista di lunghezza 100 - N contenente soli 0.

cambio_valori(+Lista1, -Lista2)		fino a quando Lista1 è piena, riempie di 0 Lista2.


popola_memoria(+ElencoIstruzioni, -Mem)		chiama popola_memoria_istruzioni/2 ed esegue il padding della memoria.

popola_memoria_istruzioni(+ElencoIstruzioni, -MemProv)		richiama creazione_istruzioni/2. Restituisce la memoria 
								contenente le istruzioni in codice macchiina.

creazione_indirizzi_etichette(+Lista1, +Pos, -Lista2)	Lista1 è la lista delle parole dell'istruzione.
							Il predicato rimuove l'etichetta precedente l'istruzione e
							sostituisce l'etichetta successiva l'istruzione con il 
							corrispondente valore numerico.

sostituzione_etichette(+Lista1, -Lista2)	Lista1 è una lista di stringhe (righe del file assembly).
						Richiama creazione_indirizzi_etichette/3.
						Lista2 è una lista di stringhe dove le etichette sono state sostituite
						con il loro corrispettivo numerico.

ricerca_pattern(+ListaIstruzione, +Pos)		ListaIstruzione è una lista che contiene le singole parole dell'istruzione.
						Controlla se la prima parola dell'istruzione è un'etichetta:
						se sì, richiama creazione_etichetta/2, altrimenti interrompe la ricerca del pattern.

ricerca_etichette(+ListaDiStringhe, +Pos)	applica ricerca_pattern/2 ai singoli elementi della lista ListaDiStringhe.			

-------------------------------------------------------------------------------------------------------------------------------------

Predicati  simulatore LMC:

input(+In1, -In2, -Acc)		 	

output(+Acc, +Out1, -Out2)

incrementa_pc(+OldPc, -NewPc)

addizione(+N1, +N2, -Acc, -Flag)

sottrazione(+N1, +N2, -Acc, -Flag)

store(+Acc, +XX, +Mem1, -Mem2)

load(+XX, +Mem1, -Acc)

branch(+XX, -Pc)

branch_if_zero(+XX, +Flag, +Acc, +Pc1, -Pc2)

branch_if_positive(+XX, +Flag, +Pc1, -Pc2)

execution_loop(+State, -Out)	richiama ricorsivamente one_instruction/2. Se uno dei NewState prodotti dalla
				one_instruction/2 è un halted_state, il predicato produce un caso di halt.

one_instruction(+State, -NewState)	State e NewState sono rispettivamente state(Acc1, Pc1, Mem1, In1, Out1, Flag1)
					e state(Acc2, Pc2, Mem2, In2, Out2, Flag2).
					Chiamiamo Istruzione l'elemento di Mem1 alla posizione Pc1 e
					chiamiamo Content l'elemento di Mem1 alla posizione XX (dove XX è Istruzione%100).
					Se:
					- (Istruzione >= 0 e Istruzione <= 99) NewState è un halted_state;
					- (Istruzione >= 400 e Istruzione <= 499 o
					   Istruzione  = 900 o
					   Istruzione >= 903 e Istruzione <= 999) il programma viene interrotto;
					- (Istruzione >= 100 e Istruzione <= 199) chiama addizione(Content, Acc1, Acc2, Flag2),
										  incrementa il pc con incrementa_pc/2,
										  e setta le variabili rimanenti ai valori precedenti;
					- (Istruzione >= 200 e Istruzione <= 299) chiama sottrazione/4 analogamente a quanto sopra;
					- (Istruzione >= 300 e Istruzione <= 399) chiama store/4 analogamente a quanto sopra;
					- (Istruzione >= 500 e Istruzione <= 599) chiama load/3 analogamente a quanto sopra;
					- (Istruzione >= 600 e Istruzione <= 699) chiama branch/2;
					- (Istruzione >= 700 e Istruzione <= 799) chiama branch_if_zero/5;
					- (Istruzione >= 800 e Istruzione <= 899) chiama branch_if_positive/4;
					- (Istruzione  = 901) chiama input/3;
					- (Istruzione  = 902) chiama output/3.








