%%%% -*- Mode: Prolog -*-


%%% lmc_load/2

lmc_load(Filename, _) :-
      open(Filename, read, In),
      read_string(In, _, FileTxt),
      close(In),
      split_string(FileTxt, "\n", "\n", Righe),
      errore_file(Righe, true), % contiene errori
      abort(),
      !.

lmc_load(Filename, Mem) :-
      open(Filename, read, In),
      read_string(In, _, FileTxt),
      close(In),
      string_lower(FileTxt, FileTxt2),
      split_string(FileTxt2, "\n", "\n", Righe),
      rimuovi_commento(Righe, Righe2),
      ricerca_etichette(Righe2, 0),
      sostituzione_etichette(Righe2, StringaFinale),
      popola_memoria(StringaFinale, Mem),
      retractall(etichetta(_, _)).

%%% lmc_run/3

lmc_run(Filename, In, Out) :-
      lmc_load(Filename, Mem),
      length(Mem, N),
      N =< 100,
      !,
      execution_loop(state(0, 0, Mem, In, [], noflag ), Out).


%% Controllo righe

%%% rimuovi_commento/2

rimuovi_commento([], []) :- % Lista Righe vuota
      !.

rimuovi_commento([X], []) :- % una sola riga, tutta commento
      string_chars(X, L),
      commento_al_num(L, N),
      N == 0,
      !.

rimuovi_commento([X], []) :- % una sola riga, stringa vuota
      string_chars(X, L),
      commento_al_num(L, N),
      N == -2,
      length(L, Lung),
      Lung == 0,
      !.

rimuovi_commento([X], [X]) :- % una sola riga, nessun commento
      string_chars(X, L),
      commento_al_num(L, N),
      N == -2,
      length(L, Lung),
      Lung > 0,
      !.

rimuovi_commento([X], [Head]) :- % una sola riga con commento
      string_chars(X, L),
      commento_al_num(L, N),
      N > 0,
      split_string(X, "/", "/", [Head | _]),
      !.

rimuovi_commento([X | T], [X | T2]) :- % più righe, nessun commento
      string_chars(X, L),
      length(L, Lung),
      commento_al_num(L, N),
      N == -2,
      Lung > 0,
      rimuovi_commento(T, T2),
      !.

rimuovi_commento([X | T], [Head | T2]) :- % più righe, con commento
      string_chars(X, L),
      commento_al_num(L, N),
      N > 0,
      split_string(X, "/", "/", [Head | _]),
      rimuovi_commento(T, T2),
      !.

rimuovi_commento([X | T], T2) :- % più righe, commento ad inizio riga
      string_chars(X, L),
      commento_al_num(L, N),
      N == 0,
      rimuovi_commento(T, T2),
      !.

rimuovi_commento([X | T], T2) :- % più righe, X è una stringa vuota
      string_chars(X, L),
      commento_al_num(L, N),
      N == -2,
      length(L, Lung),
      Lung == 0,
      rimuovi_commento(T, T2).


%%% errore_stringa/2

errore_stringa(Stringa, false) :-
      string_chars(Stringa, ListaCaratteri),
      commento_al_num(ListaCaratteri, N),
      N >= 0,
      !.

errore_stringa(Stringa, false) :-
      string_chars(Stringa, ListaCaratteri),
      commento_al_num(ListaCaratteri, N),
      N == -2,
      !.

errore_stringa(Stringa, true) :-
      string_chars(Stringa, ListaCaratteri),
      commento_al_num(ListaCaratteri, N),
      N == -1.


%%% errore_file/2

errore_file([], false) :-
      !.
errore_file([X | _], true) :-
      errore_stringa(X, Bool1),
      Bool1 == true,
      !.
errore_file([X | T], Bool):-
      errore_stringa(X, Bool1),
      Bool1 == false,
      errore_file(T, Bool).

%%% commento_al_num/2

commento_al_num(Stringa, N) :- % -2 codice
      string_chars(Stringa, Lista),
      slash_presente(Lista, false),
      N is -2,
      !.

commento_al_num(Stringa, N) :- % >= 0 commento
      string_chars(Stringa, Lista),
      slash_presente(Lista, true),
      nth0(N, Lista, '/'),
      X is N + 1,
      nth0(X, Lista, '/') ,
      !.

commento_al_num(Stringa, N) :- % -1 errore
      string_chars(Stringa, Lista),
      slash_presente(Lista, true),
      N is -1.


%%% slash_presente/2

slash_presente([], false).

slash_presente([X | _], Boolean) :-
      X == '/',
      Boolean = true,
      !.
slash_presente([X | T], Boolean) :-
      X \= '/',
      slash_presente(T, Boolean).


%% Etichette

%%% ricerca_etichette/2

ricerca_etichette([X | T], N1) :- % input: lista di stringhe da codice
      split_string(X, " ", " ", ElencoParole),
      ricerca_pattern(ElencoParole, N1), % N1 è l'indirizzo dell'etichetta
      N2 is N1 + 1,
      ricerca_etichette(T, N2),
      !.

ricerca_etichette([], _).


%%% ricerca_pattern/2

ricerca_pattern([X | _], N) :- % se non è carattere riservato crea l'etichetta
    X \= "add",
    X \= "sub",
    X \= "sta",
    X \= "lda",
    X \= "bra",
    X \= "brz",
    X \= "brp",
    X \= "inp",
    X \= "out",
    X \= "dat",
    X \= "hlt",
    creazione_etichetta(X, N),
    !.

ricerca_pattern([_ | _], _). % caso residuale


%%% creazione_etichetta/2

creazione_etichetta(Label, N) :-
        assertz(etichetta(Label, N)).


%%% sostituzione_etichette/2

sostituzione_etichette([], []).

sostituzione_etichette([X | T], [X2 | T2]) :- % input: lista stringhe da codice
      string_lower(X, StringaMinuscola),
      split_string(StringaMinuscola, " ", " ", ElencoParole),
      creazione_indirizzi_etichette(ElencoParole, 0, ElencoParoleSostituite),
      atomics_to_string(ElencoParoleSostituite, " ", X2),
      sostituzione_etichette(T, T2).


%%% creazione_indirizzi_etichette/3

creazione_indirizzi_etichette([], _, []).

creazione_indirizzi_etichette([X | T], Pos, T2) :- % rimuove la prima etichetta
      Pos == 0,
      Pos2 is Pos + 1,
      X \= "add",
      X \= "sub",
      X \= "sta",
      X \= "lda",
      X \= "bra",
      X \= "brz",
      X \= "brp",
      X \= "inp",
      X \= "out",
      X \= "dat",
      X \= "hlt",
      creazione_indirizzi_etichette(T, Pos2, T2),
      !.

creazione_indirizzi_etichette([X1, _], Pos, _) :-
      Pos == 0,
      X1 == "inp",
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X1, _], Pos, _) :-
      Pos == 0,
      X1 == "out",
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X1, _], Pos, _) :-
      Pos == 0,
      X1 == "hlt",
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X1, _], Pos, _) :-
      Pos > 0,
      X1 == "inp",
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X1, _], Pos, _) :-
      Pos > 0,
      X1 == "out",
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X1, _], Pos, _) :-
      Pos > 0,
      X1 == "hlt",
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X1, X2 | _], Pos, _) :-
      Pos = 0,
      X1 == "dat",
      \+number_string(_, X2),
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X | T], Pos, [X | T2]) :-
      Pos == 0,
      Pos2 is Pos + 1,
      creazione_indirizzi_etichette(T, Pos2, T2),
      !.

creazione_indirizzi_etichette([X1, X2 | _], Pos, _) :-
      Pos > 0,
      X1 == "dat",
      \+number_string(_, X2),
      retractall(etichetta(_, _)),
      abort().

creazione_indirizzi_etichette([X | T], Pos, [X2 | T]) :-
      Pos > 0,
      etichetta(X, N),
      X2 is N,
      !.

creazione_indirizzi_etichette([X | T], Pos, [X | T2]) :-
      Pos > 0,
      Pos2 is Pos + 1,
      creazione_indirizzi_etichette(T, Pos2, T2).


%% popolazione memoria

%%% popola_memoria/2

popola_memoria([], Mem) :- %caso istruzioni vuote
      riempimento_memoria(0, Mem).

popola_memoria(ElencoIstruzioni, Mem) :- %caso istruzioni valide
      popola_memoria_istruzioni(ElencoIstruzioni, MemProv),
      length(MemProv, N),
      riempimento_memoria(N, MemComplementare),
      append(MemProv, MemComplementare, Mem).


%%% popola_memoria_istruzioni/2

popola_memoria_istruzioni([], []).

popola_memoria_istruzioni([X | T], [X2 | T2]) :-
      split_string(X, " ", " ", ElencoParole),
      creazione_istruzioni(ElencoParole, X2),
      popola_memoria_istruzioni(T, T2).


%%% creazione_istruzioni/2


creazione_istruzioni(["" | T], Val) :-
      creazione_istruzioni(T, Val),
      !.

creazione_istruzioni([""], 0) :-
      !.

creazione_istruzioni([X1, X2], _) :-
      X1 \= "dat",
      number_string(N, X2),
      N > 100,
      retractall(etichetta(_, _)),
      abort(),
      !.

creazione_istruzioni([X1, X2], _) :-
      X1 == "dat",
      number_string(N, X2),
      N > 1000,
      retractall(etichetta(_, _)),
      abort(),
      !.


creazione_istruzioni([X1, X2], Val) :-
      X1 == "add",
      number_string(N, X2),
      Val is 100 + N,
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "sub",
      number_string(N, X2),
      Val is 200 + N,
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "sta",
      number_string(N, X2),
      Val is 300 + N,
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "lda",
      number_string(N, X2),
      Val is 500 + N,
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "bra",
      number_string(N, X2),
      Val is 600 + N,
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "brz",
      number_string(N, X2),
      Val is 700 + N,
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "brp",
      number_string(N, X2),
      Val is 800 + N,
      !.

creazione_istruzioni([X1, _], 901) :-
      X1 == "inp",
      !.

creazione_istruzioni([X1], 901) :-
      X1 == "inp",
      !.

creazione_istruzioni([X1, _], 902) :-
      X1 == "out",
      !.

creazione_istruzioni([X1], 902) :-
      X1 == "out",
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "hlt",
      number_string(N, X2),
      Val is 0 + N,
      !.

creazione_istruzioni([X1], 0):-
      X1 == "hlt",
      !.

creazione_istruzioni([X1, X2], Val) :-
      X1 == "dat",
      number_string(Val, X2),
      !.

creazione_istruzioni([X1], 0) :-
      X1 == "dat".


%%% riempimento_memoria/2

riempimento_memoria(N, MemComplementare) :-
      M is 100 - N,
      randseq(M, 100, MemProv),
      cambio_valori(MemProv, MemComplementare).


%%% cambio_valori/2

cambio_valori([], []).

cambio_valori([_ | T], [X2 | T2]) :-
      X2 = 0,
      cambio_valori(T, T2).


%% corpo principale

%%% execution_loop/2

execution_loop(state(Acc, Pc, Mem, In, Out, Flag), Out) :- % caso halt
      one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                      halted_state(_, Pc2, _, _, _, _)
                     ),
      Pc2 == -1,
      !.

execution_loop(state(Acc, Pc, Mem, In, Out, Flag), Out3) :- % caso normale
      one_instruction(state(Acc, Pc, Mem, In, Out, Flag),
                      state(Acc2, Pc2, Mem2, In2, Out2, Flag2)
                     ),
      execution_loop(state(Acc2, Pc2, Mem2, In2, Out2, Flag2), Out3),
      !.


%%% one_instruction/2

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, Flag1), % caso halt
                halted_state(Acc1, -1, Mem1, In1, Out1, Flag1)) :-
      nth0(Pc1, Mem1, Istruzione),
      Istruzione >= 0,
      Istruzione =< 99,
      !.

one_instruction(state(_, Pc1, Mem1, _, _, _), % caso istruzione non valida
		state(_, _, _, _, _, _)) :-
      nth0(Pc1, Mem1, Istruzione),
      Istruzione >= 400,
      Istruzione =< 499,
      abort().

one_instruction(state(_, Pc1, Mem1, _, _, _),
		state(_, _, _, _, _, _)) :-
      nth0(Pc1, Mem1, Istruzione),
      Istruzione == 900,
      abort().

one_instruction(state(_, Pc1, Mem1, _, _, _),
		state(_, _, _, _, _, _)) :-
      nth0(Pc1, Mem1, Istruzione),
      Istruzione >= 903,
      Istruzione =< 999,
      abort().

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, _), % ADD
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      nth0(XX, Mem1, Content),
      Istruzione >= 100,
      Istruzione =< 199,
      addizione(Content, Acc1, Acc2, Flag2),
      incrementa_pc(Pc1, Pc2),
      Mem2 = Mem1,
      In2 = In1,
      Out2 = Out1,
      !.

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, _), % SUB
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      nth0(XX, Mem1, Content),
      Istruzione >= 200,
      Istruzione =< 299,
      sottrazione(Content, Acc1, Acc2, Flag2),
      incrementa_pc(Pc1, Pc2),
      Mem2 = Mem1,
      In2 = In1,
      Out2 = Out1,
      !.

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, Flag1), % STA
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      Istruzione >= 300,
      Istruzione =< 399,
      store(Acc1, XX, Mem1, Mem2),
      incrementa_pc(Pc1, Pc2),
      Acc2 is Acc1,
      In2 = In1,
      Out2 = Out1,
      Flag2 = Flag1,
      !.

one_instruction(state(_, Pc1, Mem1, In1, Out1, Flag1), % LDA
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      Istruzione >= 500,
      Istruzione =< 599,
      load(XX, Mem1, Acc2),
      incrementa_pc(Pc1, Pc2),
      Mem2 = Mem1,
      In2 = In1,
      Out2 = Out1,
      Flag2 = Flag1,
      !.

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, Flag1), % BRA
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      Istruzione >= 600,
      Istruzione =< 699,
      branch(XX, Pc2),
      Acc2 is Acc1,
      Mem2 = Mem1,
      In2 = In1,
      Out2 = Out1,
      Flag2 = Flag1,
      !.

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, Flag1), % BRZ
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      Istruzione >= 700,
      Istruzione =< 799,
      branch_if_zero(XX, Flag1, Acc1, Pc1, Pc2),
      Acc2 is Acc1,
      Mem2 = Mem1,
      In2 = In1,
      Out2 = Out1,
      Flag2 = Flag1,
      !.

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, Flag1), % BRP
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      XX is mod(Istruzione, 100),
      Istruzione >= 800,
      Istruzione =< 899,
      branch_if_positive(XX, Flag1, Pc1, Pc2),
      Acc2 is Acc1,
      Mem2 = Mem1,
      In2 = In1,
      Out2 = Out1,
      Flag2 = Flag1,
      !.

one_instruction(state(_, Pc1, Mem1, In1, Out1, Flag1), % INP
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      Istruzione == 901,
      input(In1, In2, Acc2),
      incrementa_pc(Pc1, Pc2),
      Mem2 = Mem1,
      Out2 = Out1,
      Flag2 = Flag1,
      !.

one_instruction(state(Acc1, Pc1, Mem1, In1, Out1, Flag1), % OUT
                state(Acc2, Pc2, Mem2, In2, Out2, Flag2)) :-
      nth0(Pc1, Mem1, Istruzione),
      Istruzione == 902,
      output(Acc1, Out1, Out2),
      incrementa_pc(Pc1, Pc2),
      Acc2 is Acc1,
      Mem2 = Mem1,
      In2 = In1,
      Flag2 = Flag1.


%% metodi LMC

%%% incrementa_pc/2

incrementa_pc(OldPc, NewPc) :-
      OldPc >= 0,
      OldPc =< 98,
      NewPc is OldPc + 1,
      !.

incrementa_pc(OldPc, NewPc) :-
      OldPc == 99,
      NewPc is 0.


%%% addizione/4

addizione(N1, N2, Acc, Flag) :-
      X is N1 + N2,
      X < 1000,
      Flag = noflag,
      Acc is mod(X, 1000),
      !.

addizione(N1, N2, Acc, Flag) :-
      X is N1 + N2,
      X >= 1000,
      Flag = flag,
      Acc is mod(X, 1000).


%%% sottrazione/4

sottrazione(N1, N2, Acc, flag) :-
      X is N2 - N1,
      X < 0,
      Acc is mod(X, 1000),
      !.

sottrazione(N1, N2, Acc, noflag) :-
      X is N2 - N1,
      X >= 0,
      Acc is mod(X, 1000).


%%% store/4

store(X, 0, [_ | T], [X | T]) :-
      !.

store(X, Pos, [H | T], [H | R]) :-
      Pos > 0,
      XX is Pos - 1,
      store(X, XX, T, R),
      !.


%%% load/3

load(XX, Mem1, Acc) :-
      nth0(XX, Mem1, Val),
      Acc is Val.


%%% branch/2

branch(XX, Pc) :-
      Pc is XX.


%%% branch_if_zero/5

branch_if_zero(XX, Flag, Acc, _, Pc2) :-
      Acc == 0,
      Flag == noflag,
      Pc2 is XX,
      !.

branch_if_zero(_, _, _, Pc1, Pc2) :-
      incrementa_pc(Pc1, Pc2).


%%% branch_if_positive/4

branch_if_positive(XX, Flag, _, Pc2) :-
      Flag == noflag,
      Pc2 is XX,
      !.

branch_if_positive(_, _, Pc1, Pc2) :-
      incrementa_pc(Pc1, Pc2).


%%% input/3

input([], _, _) :-
      abort().

input([H | T], T, Acc) :-
      Acc is H.


%%% output/3

output(Acc, [], [Acc]) :-
      !.

output(Acc, Out1, Out2) :-
      append(Out1, [Acc], Out2).
















