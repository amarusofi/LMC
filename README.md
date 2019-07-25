# Little Man Computer
In collaborazione con [Jacopo De Angelis](https://github.com/JacopoDeAngelis)

## Overview del progetto

Il little man computer (LMC) è un semplice modello di computer creato per scopi didattici. Esso possiede 100 celle di memoria (numerate da 0 a 99) ognuna della quali può contenere un numero da 0 a 999 (estremi inclusi). Il computer possiede un solo registro, detto accumulatore, una coda di input ed una coda di output. LMC possiede un numero limitato di tipi di istruzioni ed un equivalente assembly altrettanto semplificato. Lo scopo del progetto è quello di produrre

- Un simulatore del LMC che dato il contenuto iniziale delle memoria (una lista di 100 numeri) e una sequenza di valori di input simuli il  comportamento del LMC e produca il contenuto della coda di output dopo l’arresto del LMC.

- Un assembler che, dato un file scritto nell’assembly semplificato del LMC produca il contenuto iniziale della memoria.

La parte rimanente di questo testo dettaglierà l’architettura del LMC, la sintassi dell’assembly e i predicati/funzioni che le implementazioni in Prolog e Common Lisp devono implementare.

## Architettura del LMC

Il LMC è composto dalle seguenti componenti:

- Una memoria di 100 celle numerate tra 0 e 99. Ogni cella può contenere un numero tra 0 e 999. Non viene effettuata alcuna distinzione tra dati e istruzioni: a seconda del momento il contenuto di una certa cella può essere interpretato come un’istruzione (con una semantica che verrà spiegata in seguito) oppure come un dato (e, ad esempio, essere sommato ad un altro valore).

- Un registro accumulatore (inizialmente zero).

- Un program counter. Il program counter contiene l’indirizzo dell’istruzione da eseguire ed è inizialmente zero. Se non viene sovrascritto da altre istruzioni (salti condizionali e non condizionali) viene incrementato di uno ogni volta che un’istruzione viene eseguita. Se raggiunge il valore 999 e viene incrementato il valore successivo è zero.

- Una coda di input. Questa coda contiene tutti i valori forniti in input al LMC, che sono necessariamente numeri compresi tra 0 e 999. Ogni volta che l’LMC legge un valore di input esso viene eliminato dalla coda.

- Una coda di output. Questa coda è inizialmente vuota e contiene tutti i valori mandati in output dal LMC, che sono necessariamente numeri compresi tra 0 e 999. La coda è strutturata in modo tale da avere in testa il primo output prodotto e come ultimo elemento l’ultimo output prodotto: i valori di output sono quindi in ordine cronologico.

- Un flag. Ovvero un singolo bit che può essere acceso o spento. Inizialmente esso è zero (flag assente). Solo le istruzioni aritmetiche modificano il valore del flag e, in particolare, un flag a uno (flag presente) indica che l’ultima operazione aritmetica eseguita ha prodotto un risultato maggiore di 999 o minore di 0. Un flag assente indica invece che il valore prodotto dall’ultima operazione aritmetica ha prodotto un risultato compreso tra 0 e 999.

La seguente tabella rappresenta come le istruzioni presenti in memoria debbano essere interpretate:

| Valore | Nome istruzione    | Significato                                                                                                                                                                                                                                                                                                                             |
| ------ | ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1xx    | Addizione          | Somma il contenuto della cella di memoria xx con il valore contenuto nell’accumulatore e scrive il valore risultante nell’accumulatore. Il valore salvato nell’accumulatore è la somma modulo 1000. Se la somma non supera 1000 il flag è impostato ad assente, se invece raggiunge o supera 1000 il flag è impostato a presente.       |
| 2xx    | Sottrazione        | Sottrae il contenuto della cella di memoria xx dal valore contenuto nell’accumulatore e scrive il valore risultante nell’accumulatore. Il valore salvato nell’accumulatore è la differenza modulo 1000. Se la differenza è inferiore a zero il flag è impostato a presente, se invece è positiva o zero il flag è impostato ad assente. |
| 3xx    | Store              | Salva il valore contenuto nell’accumulatore nella cella di memoria avente indirizzo xx. Il contenuto dell’accumulatore rimane invariato.                                                                                                                                                                                                |
| 5xx    | Load               | Scrive il valore contenuto nella cella di memoria di indirizzo xx nell’accumulatore. Il contenuto della cella di memoria rimane invariato.                                                                                                                                                                                              |
| 6xx    | Branch             | Salto non condizionale. Imposta il valore del program counter a xx.                                                                                                                                                                                                                                                                     |
| 7xx    | Branch if zero     | Salto condizionale. Imposta il valore del program counter a xx solamente se il contenuto dell’accumulatore è zero e se il flag è assente.                                                                                                                                                                                               |
| 8xx    | Branch if positive | Salto condizionale. Imposta il valore del program counter a xx solamente se il flag è assente.                                                                                                                                                                                                                                          |
| 901    | Input              | Scrive il contenuto presente nella testa della coda in input nell’accumulatore e lo rimuove dalla coda di input.                                                                                                                                                                                                                        |
| 902    | Output             | Scrive il contenuto dell’accumulatore alla fine della coda di output. Il contenuto dell’accumulatore rimane invariato.                                                                                                                                                                                                                  |
| 0xx    | Halt               | Termina l’esecuzione del programma. Nessuna ulteriore istruzione viene eseguita.                                                                                                                                                                                                                                                        |

Alcuni devi valori non corrispondono a nessuna istruzione. Ad esempio tutti i numeri tra 400 e 499 non hanno un corrispettivo. Questo significa che corrispondono a delle istruzioni non valide (illegal instructions) e che LMC si fermerà con una condizione di errore.

Quindi, ad esempio, se l’accumulatore contiene il valore 42, il program counter ha valore 10 ed il contenuto della cella numero 10 è 307, il LMC eseguirà una istruzione di store, dato che il valore è nella forma 3xx. In particolare, il contenuto dell’accumulatore, ovvero 42, verrà scritto nella cella di memoria numero 7 (dato che xx corrisponde a 07). Il program counter verrà poi incrementato di uno, assumendo il valore 11. La procedura verrà ripetuta finché non verrà incontrata un’istruzione di halt o un’istruzione non valida.

## Assembly per LMC

Oltre a fornire una simulazione per il LMC si deve essere anche in grado di passare da un programma scritto in codice assembly per LMC (che verrà successivamente dettagliato) al contenuto iniziale della memoria del LMC, convertendo quindi il codice assembly in codice macchina.

Nel file sorgente assembly ogni riga contiene al più una etichetta ed una istruzione. Ogni istruzione corrisponde al contenuto di una cella di memoria. La prima istruzione assembly presente nel file corrisponderà al valore contenuto nella cella 0, la seconda al valore contenuto nella cella 1, e così via.

| Istruzione | Valori possibili per xx | Significato                                                                                                                  |
| ---------- | ----------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| ADD xx     | Indirizzo o etichetta   | Esegui l’istruzione di addizione tra l’accumulatore e il valore contenuto nella cella indicata da xx                         |
| SUB xx     | Indirizzo o etichetta   | Esegui l’istruzione di sottrazione tra l’accumulatore e il valore contenuto nella cella indicata da x                        |
| STA xx     | Indirizzo o etichetta   | Esegue una istruzione di store del valore dell’accumulatore nella cella indicata da xx                                       |
| LDA xx     | Indirizzo o etichetta   | Esegue una istruzione di load dal valore contenuto nella cella indicata da xx nell’accumulatore                              |
| BRA xx     | Indirizzo o etichetta   | Esegue una istruzione di branch non condizionale al valore indicato da xx                                                    |
| BRZ xx     | Indirizzo o etichetta   | Esegue una istruzione di branch condizionale (se l’accumulatore è zero e non vi è il flag acceso) al valore indicato da xx.  |
| BRP xx     | Indirizzo o etichetta   | Esegue una istruzione di branch condizionale (se non vi è il flag acceso) al valore indicato da xx.                          |
| INP        | Nessuno                 | Esegue una istruzione di input                                                                                               |
| OUT        | Nessuno                 | Esegue una isttuzione di output                                                                                              |
| HLT        | Nessuno                 | Esegue una istruzione di halt                                                                                                |
| DAT xx     | Numero                  | Memorizza nella cella di memoria corrispondente a questa istruzione assembly il valore xx                                    |
| DAT        | Nessuno                 | Memorizza nella cella di memoria corrispondente a questa istruzione assembly il valore 0 (equivalente all’istruzione DAT 0). |

Ogni riga del file assembly con una istruzione può contenere prima dell’istruzione una etichetta, ovvero una stringa di caratteri usata per identificare la cella di memoria dove verrà salvata l’istruzione corrente. Le etichette possono poi essere utilizzate al posto degli indirizzi (ovvero numeri tra 0 e 99) all’interno del sorgente.

## Implementazioni

### Implementazione in Prolog

L’implementazione del simulatore di LMC in Prolog deve rispettare le restrizioni elencate in questa sezione.
Lo stato del LMC deve essere rappresentato da un termine composto della seguente forma:

```prolog
state(Acc, Pc, Mem, In, Out, Flag).
```

nel caso non sia stata ancora eseguita una istruzione di halt. Nel caso sia stata eseguita invece lo stato deve essere rappresentato usando il funtore halted_state invece di state:

```prolog
halted_state(Acc, Pc, Mem, In, Out, Flag).
```

Nel termine composto gli argomenti sono i seguenti:

- Acc. Un numero tra 0 e 999 che rappresenta il valore contenuto nell’accumulatore.

- Pc. Un numero tra 0 e 999 che rappresenta il valore contenuto nel program counter.

- Mem. Una lista di 100 numeri tutti compresi tra 0 e 999 che rappresenta il contenuto della memoria del LMC

- In. Una lista di numeri tra 0 e 999 che rappresenta la coda di input del LMC.

- Out. Una lista di numeri tra 0 e 999 che rappresenta la coda di output del LMC.

- Flag. Può assumere solo i valori flag e noflag, che indicano rispettivamente che il flag è presente o assente.

Per eseguire il codice del LMC deve essere presente il seguente predicato:

```prolog
one_instruction(State, NewState)
```

ove State e NewState sono stati del LMC rappresentati come descritto sopra ed il predicato è vero quando l’esecuzione di una singola istruzione a partire da State porta allo stato NewState. Il predicato fallisce nei seguenti casi:

- Lo stato State è un halting_state, ovvero il sistema è stato arrestato e non può eseguire istruzioni.

- L’istruzione da eseguire è di input ma la coda di input è vuota.

- L’istruzione da eseguire non è valida.

In tutti gli altri casi una query della forma one_instruction(State, X) dove State è
fissato e X è una variabile deve avere successo e il valore di X deve essere l’unico stato che segue allo stato fornito dopo aver eseguito l’istruzione puntata dal program counter.

Deve essere inoltre presente il seguente predicato:

```prolog
execution_loop(State, Out)
```

ove State rappresenta lo stato iniziale del LMC e Out la coda di output nel momento in cui viene raggiunto uno stato di stop (e quindi eseguita una istruzione di halt). Il predicato deve fallire nel caso l’esecuzione termini senza eseguire una istruzione di halt (ad esempio se si incontra una istruzione non valida). 

Infine, dovrete produrre due predicati per la gestione dell’assembly. Il primo è un predicato dal nome lmc_load/2 che si preoccupa di leggere un file che contiene un codice assembler e che produce il contenuto “iniziale” della memoria sistema (una lista di 100 numeri tra 0 e 999).

```prolog
lmc_load(Filename, Mem)
```

dove Filename è il nome di un file e Mem è la memoria del sistema nel suo "stato iniziale”.

Il secondo è un predicato dal nome lmc_run/3 che si preoccupa di leggere un file che contiene un codice assembler, lo carica (con lmc_load/2), imposta la coda di input al valore fornito e produce un output che è il risultato dell’invocazione di execution_loop/2.

## Implementazione in Common Lisp

L’implementazione del simulatore di LMC in Common Lisp deve rispettare le restrizioni elencate in questa sezione.

Lo stato del LMC deve essere rappresentato da una lista della seguente forma:

```lisp
(STATE :ACC <Acc> :PC <PC> :MEM <Mem> :IN <In> :OUT <Out> :FLAG <Flag>)
```

nel caso non sia stata ancora eseguita una istruzione di halt. Nel caso sia stata eseguita invece lo stato deve essere rappresentato usando il funtore HALTED-STATE invece di STATE:

```lisp
(HALTED-STATE    :ACC <Acc>

                 :PC <PC>

                 :MEM <Mem>

                 :IN <In>

                 :OUT <Out>

                 :FLAG <Flag>)
```

Nella lista qui sopra gli argomenti sono i seguenti:

- Acc. Un numero tra 0 e 999 che rappresenta il valore contenuto nell’accumulatore.

- Pc. Un numero tra 0 e 999 che rappresenta il valore contenuto nel program counter.

- Mem. Una lista di 100 numeri tutti compresi tra 0 e 999 che rappresenta il contenuto della memoria del LMC.

- In. Una lista di numeri tra 0 e 999 che rappresenta la coda di input del LMC.

- Out. Una lista di numeri tra 0 e 999 che rappresenta la coda di output del LMC.

- Flag. Può assumere solo i valori flag e noflag, che indicano rispettivamente che il flag è presente o assente.

Per eseguire il codice del LMC deve essere definita la seguente funzione:

```lisp
one-instruction State ==> NewState
```

ove State e NewState sono stati del LMC rappresentati come descritto sopra ed il predicato è vero quando l’esecuzione di una singola istruzione a partire da State porta allo stato NewState. 

Il predicato fallisce nei seguenti casi:

- Lo stato State è un HALTING-STATE, ovvero il sistema è stato arrestato e non può eseguire istruzioni.

- L’istruzione da eseguire è di input ma la coda di input è vuota.

- L’istruzione da eseguire non è valida.

In tutti gli altri casi l’invocazione della funzione (one-instruction State) dove State è fissato ritorna un nuovo stato NewState che deve essere l’unico stato che segue allo stato fornito dopo aver eseguito l’istruzione puntata dal program counter.

Deve essere inoltre presente il seguente predicato:

```lisp
execution-loop State ==> Out
```

ove State rappresenta lo stato iniziale del LMC e Out la coda di output nel momento in cui viene raggiunto uno stato di stop (e quindi eseguita una istruzione di halt). La funzione deve generare un errore nel caso l’esecuzione termini senza eseguire una istruzione di halt (ad esempio se si incontra una istruzione non valida).

Infine, dovrete produrre due funzioni per la gestione dell’assembly. La prima è una funzione dal nome lmc-load che si preoccupa di leggere un file che contiene un codice assembler e che produce il contenuto “iniziale” della memoria del sistema (una lista di 100 numeri tra 0 e 999).

```lisp
lmc-load Filename ==> Mem
```

dove Filename è il nome di un file e Mem è il contenuto della memoria nello “stato iniziale” del
sistema.
La seconda è una funzione dal nome lmc-run che si preoccupa di leggere un file che contiene un codice assembler, lo carica (con lmc-load), inizializza la coda di input al valore fornito, e produce un output che è il risultato dell’invocazione di execution-loop.
