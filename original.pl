
:-use_module(library(lists)).
:-use_module(library(system)).
:-op(900,fy,not).
:-dynamic fapt/3.
:-dynamic interogat/1.
:-dynamic scop/1.
:-dynamic interogabil/3.
:-dynamic regula/3.
:-discontiguous citeste_cuvant/3.

not(P):-P,!,fail.
not(_).

scrie_lista([]):-nl.
scrie_lista([H|T]) :-
	write(H), tab(1),
	scrie_lista(T).

scrie_lista([], Fisier):-  write(Fisier, '\n'), flush_output(Fisier).
scrie_lista([H|T], Fisier) :-
	write(Fisier, H), tab(1, Fisier),
	% write(Fisier, '\n'), flush_output(Fisier),
	scrie_lista(T, Fisier).

afiseaza_fapte :-
	write('Fapte existente în baza de cunostinte:'),
	nl,nl, write(' (Atribut,valoare) '), nl,nl,
	listeaza_fapte,nl.

listeaza_fapte:-
	fapt(av(Atr,Val),FC,_),
	write('('),write(Atr),write(','),
	write(Val), write(')'),
	write(','), write(' certitudine '),
	FC1 is integer(FC),write(FC1),
	nl,fail.
	listeaza_fapte.

% asta primeste istoricul cu indice de intrebari sau 'utiliz' daca
% a raspuns user-ul
lista_float_int([],[]).

%daca regula este diferita de 'utiliz' (adica daca e numar), converteste float
%% to int ( ca sa nu afiseze regula 2.0, ci regula 2)
%daca este 'utiliz' atunci regula ramane neschimbata
lista_float_int([Regula|Reguli],[Regula1|Reguli1]):-
	(Regula \== utiliz,
	Regula1 is integer(Regula);
	Regula ==utiliz, Regula1=Regula),
	lista_float_int(Reguli,Reguli1).

pornire :-
	retractall(interogat(_)),
	retractall(fapt(_,_,_)),
	repeat,
	write('Introduceti una din urmatoarele optiuni: '),
	nl,nl,
	write(' (Incarca Consulta Reinitiaza  Afisare_fapte  Cum   Iesire) '),
	nl,nl,write('|: '),citeste_linie([H|T]),
	executa([H|T]), H == iesire.

executa([incarca]) :-
	incarca,!,nl, %predicatul 'incarca' citeste fisierul. Cut-ul e pus ca sa nu
				  %% mai treaca la celelalte optiuni
	write('Fisierul dorit a fost incarcat'),nl.
executa([consulta]) :-
	scopuri_princ,!.
executa([reinitiaza]) :-
	retractall(interogat(_)),
	retractall(fapt(_,_,_)),!.
executa([afisare_fapte]) :-
	afiseaza_fapte,!.
executa([cum|L]) :- cum(L),!.
executa([iesire]):-!. % aici iese din program
executa([_|_]) :- %aici prinde orice alt caz de camanda incorecta
	write('Comanda incorecta! '),nl.

% Apeleaza mai intai scop(Atr) - aici se salveaza scopul S expert
%% dupa determina(Atr) - realizaeaza scopul
scopuri_princ :-
	scop(Atr),determina(Atr), afiseaza_scop(Atr),fail.
scopuri_princ.

determina(Atr) :-
	realizare_scop(av(Atr,_),_,[scop(Atr)]),!.
determina(_).

afiseaza_scop(Atr) :-
	nl,fapt(av(Atr,Val),FC,_),
	FC >= 20,scrie_scop(av(Atr,Val),FC),
	nl,fail.
afiseaza_scop(_):- nl,nl.

scrie_scop(av(Atr,Val),FC) :-
	transformare(av(Atr,Val), X),
	scrie_lista(X),tab(2),
	write(' '),
	write('factorul de certitudine este '),
	FC1 is integer(FC),write(FC1).
% primul parametru este de structura not av(atr, valoare)
%% apeleaza realizare_scop pentru a afla FC si ii pune un minus in fata
realizare_scop(not Scop,Not_FC,Istorie) :-
	realizare_scop(Scop,FC,Istorie),
	Not_FC is - FC, !.

% mai intai se uita daca scopul a fost deja obtinut
% daca nu a fost, atunci incearca sa il obtina si cauta ceva interogabil
realizare_scop(Scop,FC,_) :-
	fapt(Scop,FC,_), !.
realizare_scop(Scop,FC,Istorie) :-
	pot_interoga(Scop,Istorie),
	!,realizare_scop(Scop,FC,Istorie).
realizare_scop(Scop,FC_curent,Istorie) :-
	fg(Scop,FC_curent,Istorie).
% ne luam regula, premisele si concluzia. N = id-ul regulii
%% demonstreaza primeste toate datele din regula si calculeaza Istoria
fg(Scop,FC_curent,Istorie) :-
	regula(N, premise(Lista), concluzie(Scop,FC)),
	demonstreaza(N,Lista,FC_premise,Istorie),
	ajusteaza(FC,FC_premise,FC_nou),
	actualizeaza(Scop,FC_nou,FC_curent,N),
	FC_curent == 100,!.
fg(Scop,FC,_) :- fapt(Scop,FC,_).

pot_interoga(av(Atr,_),Istorie) :-
	not interogat(av(Atr,_)),
	interogabil(Atr,Optiuni,Mesaj),
	interogheaza(Atr,Mesaj,Optiuni,Istorie),nl,
	asserta( interogat(av(Atr,_)) ).

cum([]) :- write('Scop? '),nl,
	write('|:'),citeste_linie(Linie),nl,
	transformare(Scop,Linie), cum(Scop).
cum(L) :-
	transformare(Scop,L),nl, cum(Scop).
cum(not Scop) :-
	fapt(Scop,FC,Reguli),
	lista_float_int(Reguli,Reguli1),
	FC < -20,transformare(not Scop,PG),
	append(PG,[a,fost,derivat,cu, ajutorul, 'regulilor: '|Reguli1],LL),
	scrie_lista(LL),nl,afis_reguli(Reguli),fail.
cum(Scop) :-
	fapt(Scop,FC,Reguli),
	lista_float_int(Reguli,Reguli1),
	FC > 20,transformare(Scop,PG),
	append(PG,[a,fost,derivat,cu, ajutorul, 'regulilor: '|Reguli1],LL),
	scrie_lista(LL),nl,afis_reguli(Reguli),
	fail.
cum(_).
% pentru subpunctul f, aici trebuie modificat
afis_reguli([]).
% aici primeste istoricul. ia indicele si apeleaza afis_regula(N)
%% de unde ia regula, premisele si concluzia
%% si mai jos putem modifica formatul
afis_reguli([N|X]) :-
	afis_regula(N),
	premisele(N),
	afis_reguli(X).
afis_regula(N) :-
	regula(N, premise(Lista_premise),concluzie(Scop,FC)),
	NN is integer(N),
	scrie_lista(['reg(',NN,')']),
	nl,
	transformare(Scop,Scop_tr),
	write(Scop_tr),
	FC1 is integer(FC),Scop_tr = [N_Scop,_,V_Scop],
	scrie_lista([N_Scop,'~',V_Scop,'~ valoare factor cert ~',FC1]),
	scrie_lista(['  enumerare_premise (']),
	scrie_lista_premise(Lista_premise),
	scrie_lista([')']),nl.
	%append(['   '],Scop_tr,L1),
	%scrie_lista(LL),nl.

scrie_lista_premise([]).
scrie_lista_premise([H|T]) :-
	transformare(H,H_tr),
	tab(5),scrie_lista(H_tr),
	scrie_lista_premise(T).

transformare(av(A,da),[A]) :- !.
transformare(not av(A,da), [not,'(',A,')']) :- !.
transformare(av(A,nu),[not,'(',A,')']) :- !.
transformare(av(A,V),[A,'~',V]).

% aici face o afisare arborescenta
premisele(N) :-
	regula(N, premise(Lista_premise), _),
	!, cum_premise(Lista_premise).

cum_premise([]).
cum_premise([Scop|X]) :-
	cum(Scop),
	cum_premise(X).

interogheaza(Atr,Mesaj,[da,nu],Istorie) :-
	!,write(Mesaj),nl,
	de_la_utiliz(X,Istorie,[da,nu]),
	det_val_fc(X,Val,FC),
	asserta( fapt(av(Atr,Val),FC,[utiliz]) ).
interogheaza(Atr,Mesaj,Optiuni,Istorie) :-
	write(Mesaj),nl,
	citeste_opt(VLista,Optiuni,Istorie),
	assert_fapt(Atr,VLista).

citeste_opt(X,Optiuni,Istorie) :-
	append(['('],Optiuni,Opt1),
	append(Opt1,[')'],Opt),
	scrie_lista(Opt),
	de_la_utiliz(X,Istorie,Optiuni).

de_la_utiliz(X,Istorie,Lista_opt) :-
	repeat,write(': '),citeste_linie(X),
	proceseaza_raspuns(X,Istorie,Lista_opt).

proceseaza_raspuns([de_ce],Istorie,_) :- nl,afis_istorie(Istorie),!,fail.
% daca ajungem aici, inseamna ca avem un raspuns de
%% la user si verificam daca raspunsul se afla in lista optiunilor
proceseaza_raspuns([X],_,Lista_opt):-
	member(X,Lista_opt).
% daca in raspuns user-ul da si FC, acesta este luat
%% in considerare si suprascrie FC initial al atributului
proceseaza_raspuns([X,'~',valoare, factor, cert, '~',FC],_,Lista_opt):-
	member(X,Lista_opt),float(FC).

assert_fapt(Atr,[Val,'~',valoare, factor, cert, '~',FC]) :-
	!,asserta( fapt(av(Atr,Val),FC,[utiliz]) ).
assert_fapt(Atr,[Val]) :-
	asserta( fapt(av(Atr,Val),100,[utiliz])).

det_val_fc([nu],da,-100).
det_val_fc([nu,FC],da,NFC) :- NFC is -FC.
det_val_fc([nu,'~',valoare, factor, cert, '~',FC],da,NFC) :- NFC is -FC.
det_val_fc([Val,FC],Val,FC).
det_val_fc([Val,'~',valoare, factor, cert, '~',FC],Val,FC).
det_val_fc([Val],Val,100).

afis_istorie([]) :- nl.
afis_istorie([scop(X)|T]) :-
	scrie_lista([scop,X]),!,
	afis_istorie(T).
afis_istorie([N|T]) :-
	afis_regula(N),!,afis_istorie(T).

demonstreaza(N,ListaPremise,Val_finala,Istorie) :-
	dem(ListaPremise,100,Val_finala,[N|Istorie]),!.

dem([],Val_finala,Val_finala,_).
dem([H|T],Val_actuala,Val_finala,Istorie) :-
	realizare_scop(H,FC,Istorie),
	Val_interm is min(Val_actuala,FC),
	Val_interm >= 20,
	dem(T,Val_interm,Val_finala,Istorie).

actualizeaza(Scop,FC_nou,FC,RegulaN) :-
	fapt(Scop,FC_vechi,_),
	combina(FC_nou,FC_vechi,FC),
	retract( fapt(Scop,FC_vechi,Reguli_vechi) ),
	asserta( fapt(Scop,FC,[RegulaN | Reguli_vechi]) ),!.
actualizeaza(Scop,FC,FC,RegulaN) :-
	asserta( fapt(Scop,FC,[RegulaN]) ).
% aici se ajusteaza FC in functie de niste formule
ajusteaza(FC1,FC2,FC) :-
	X is FC1 * FC2 / 100,
	FC is round(X).
combina(FC1,FC2,FC) :-
	FC1 >= 0,FC2 >= 0,
	X is FC2*(100 - FC1)/100 + FC1,
	FC is round(X).
combina(FC1,FC2,FC) :-
	FC1 < 0,FC2 < 0,
	X is - ( -FC1 -FC2 * (100 + FC1)/100),
	FC is round(X).
combina(FC1,FC2,FC) :-
	(FC1 < 0; FC2 < 0),
	(FC1 > 0; FC2 > 0),
	FCM1 is abs(FC1),FCM2 is abs(FC2),
	MFC is min(FCM1,FCM2),
	X is 100 * (FC1 + FC2) / (100 - MFC),
	FC is round(X).

incarca :-
	write('Introduceti numele fisierului care doriti sa fie incarcat: '),nl, write('|:'),read(F),
	exists_file(F),!,incarca(F).
incarca:-write('Nume incorect de fisier! '),nl,fail.

incarca(F) :-
	retractall(interogat(_)),retractall(fapt(_,_,_)),
	retractall(scop(_)),retractall(interogabil(_,_,_)),
	retractall(regula(_,_,_)),
	see(F),incarca_reguli,seen,!.

incarca_reguli :-
	repeat,citeste_propozitie(L), %citeste linia pana la \n
	%write(L), %% DEBUG write(L)
	proceseaza(L), %% proceseaza - e cel care interpreteaza informatia
	L == [end_of_file],nl.

proceseaza([end_of_file]):-!.
proceseaza(L) :-
	% fiecare propozitie se transforma intr-un fapt
	% trad: in R pune faptul pe care trebuie sa il assertam
	% foloseste assertz pentru a le pune fix in ordinea in care sunt citite
	trad(R,L,[]),
	write(L), %% DEBUG!!!
	nl,
	write(R),
	assertz(R), !.
% reguli DCG  - reguli speciale de parsare
% predicat care face propozitii de tip: subiect predicat complement
% articol + subs = subiect; predicat = verb; complement = prepozitie + substantiv
% deci trad asta stie ca daca ii vine o propozitie de genul scopul
%% este [ceva], atunci [ceva] e returnat in X
% scop(X) este R-ul de mai sus. Deci R este scop de X daca
%% trad se descompune in 'scopul este ............'
trad(scop(X)) --> [scopul,'~',X].
trad(scop(X)) --> [scopul,X].
trad(interogabil(Atr,M,P)) -->
	% daca este intrebare:
	% intreaba atributul cu o lista de optiuni si mesajul de afisare
	['(',intrebare,pentru,'~',Atr],afiseaza(Atr,P),lista_optiuni(M).
% trad (ID, [per(atribut, val) ....], 'Atunci [concluzie] fc [F]')
trad(regula(N,premise(Daca),concluzie(Atunci,F))) -->
		identificator(N),atunci(Atunci,F),daca(Daca).
trad('Eroare la parsare'-L,L,_).

% lista_optiuni se descompune in cuvantul optiuni si paranteza
% lista_de_optiuni itereaza prin optiuni
% cat timp lista nu se unifica cu [element, ')'], se citeste
% recursiv.
lista_optiuni(M) --> [optiunile],lista_de_optiuni(M).
lista_de_optiuni([Element]) -->  ['-',Element,')'].
lista_de_optiuni([Element|T]) --> ['-',Element],lista_de_optiuni(T).

afiseaza(_,P) -->  [textul_intrebarii,'~',P].
afiseaza(P,P) -->  [].
% asta ia id-ul unei reguli
identificator(N) --> ['reg','(',N,')'].
%asta ia partea cu daca din premise si ia toate premizele
daca(Daca) --> lista_premise(Daca).

% se opreste cand intelneste termenul atunci,
%% altfel ia premizele, le baga in lista si apeleaza recursiv
lista_premise([Daca]) --> propoz(Daca),[')'].
% se pot pune premize cu si cu , intre ele
%% propz ia prima pereche de atribut valoare si ia lista premizelor
lista_premise([Prima|Celalalte]) --> propoz(Prima),['+'],lista_premise(Celalalte).
%lista_premise([Prima|Celalalte]) --> propoz(Prima),[','],lista_premise(Celalalte).

%atunci merge pana gaseste factorul de certitudine
atunci(Atunci,FC) --> propoz(Atunci),['~',valoare,factor,cert,'~'],[FC],[enumerare_premise,'(']. % DEBUG!!!!
% daca lipsteste cu desavarsire factorul de certitudine, il pune automat 100
atunci(Atunci,100) --> propoz(Atunci),[enumerare_premise,'('].

% asta ia bucatele din premize de tipul
% not ceva
% ceva este altceva
% ceva
propoz(not av(Atr,da)) --> [not,'(',Atr,')'].
propoz(av(Atr,Val)) --> [Atr,'~',Val].
propoz(av(Atr,da)) --> [Atr].

citeste_linie([Cuv|Lista_cuv]) :-
	get0(Car),
	citeste_cuvant(Car, Cuv, Car1),
	rest_cuvinte_linie(Car1, Lista_cuv).

% -1 este codul ASCII pt EOF

rest_cuvinte_linie(-1, []):- !.
rest_cuvinte_linie(Car,[]) :- (Car==13;Car==10), !.
rest_cuvinte_linie(Car,[Cuv1|Lista_cuv]) :-
	citeste_cuvant(Car,Cuv1,Car1),
	rest_cuvinte_linie(Car1,Lista_cuv).

citeste_propozitie([Cuv|Lista_cuv]) :-
% citeste un cuvant si apeleaza rest_cuvinte_propozitie
	get0(Car),citeste_cuvant(Car, Cuv, Car1),
	rest_cuvinte_propozitie(Car1, Lista_cuv).

% aici suntem in fisier, deci daca citim -1, atunci suntem la EOF
rest_cuvinte_propozitie(-1, []):- !.
% daca e punct, returnam lista vida pentru ca e finalul propozitiei
rest_cuvinte_propozitie(Car,[]) :- Car==46, !.
rest_cuvinte_propozitie(Car,[Cuv1|Lista_cuv]) :-
% altfel pun caracterul in lista si continui citirea de caractere
	citeste_cuvant(Car,Cuv1,Car1),
	rest_cuvinte_propozitie(Car1,Lista_cuv).

citeste_cuvant(-1,end_of_file,-1):- !.
citeste_cuvant(Caracter,Cuvant,Caracter1) :-
	caracter_cuvant(Caracter),!,
	name(Cuvant, [Caracter]),get0(Caracter1).
citeste_cuvant(Caracter, Numar, Caracter1) :-
	caracter_numar(Caracter),!,
	citeste_tot_numarul(Caracter, Numar, Caracter1).

citeste_tot_numarul(Caracter,Numar,Caracter1):-
	determina_lista(Lista1,Caracter1),
	append([Caracter],Lista1,Lista),
	transforma_lista_numar(Lista,Numar).

determina_lista(Lista,Caracter1):-
	get0(Caracter),
	(caracter_numar(Caracter),
	determina_lista(Lista1,Caracter1),
	append([Caracter],Lista1,Lista);
	\+(caracter_numar(Caracter)),
	Lista=[],Caracter1=Caracter).

transforma_lista_numar([],0).
transforma_lista_numar([H|T],N):-
	transforma_lista_numar(T,NN),
	lungime(T,L), Aux is 10^L,
	HH is H-48,N is HH*Aux+NN.

lungime([],0).
lungime([_|T],L):-
	lungime(T,L1),
	L is L1+1.

% 39 este codul ASCII pt '

citeste_cuvant(Caracter,Cuvant,Caracter1):-
	Caracter==39,!,
	pana_la_urmatorul_apostrof(Lista_caractere),
	L=[Caracter|Lista_caractere],
	name(Cuvant, L),get0(Caracter1).

pana_la_urmatorul_apostrof(Lista_caractere):-
	get0(Caracter),
	(Caracter == 39,Lista_caractere=[Caracter];
	Caracter\==39,
	pana_la_urmatorul_apostrof(Lista_caractere1),
	Lista_caractere=[Caracter|Lista_caractere1]).

citeste_cuvant(Caracter,Cuvant,Caracter1):-
	caractere_in_interiorul_unui_cuvant(Caracter),!,
	((Caracter>64,Caracter<91),!,
	Caracter_modificat is Caracter+32;
	Caracter_modificat is Caracter),
	citeste_intreg_cuvantul(Caractere,Caracter1),
	name(Cuvant,[Caracter_modificat|Caractere]).

citeste_intreg_cuvantul(Lista_Caractere,Caracter1):-
	get0(Caracter),
	(caractere_in_interiorul_unui_cuvant(Caracter),
	((Caracter>64,Caracter<91),!,
	Caracter_modificat is Caracter+32;
	Caracter_modificat is Caracter),
	citeste_intreg_cuvantul(Lista_Caractere1, Caracter1),
	Lista_Caractere=[Caracter_modificat|Lista_Caractere1]; \+(caractere_in_interiorul_unui_cuvant(Caracter)),
	Lista_Caractere=[], Caracter1=Caracter).

citeste_cuvant(_,Cuvant,Caracter1):-
	get0(Caracter),
	citeste_cuvant(Caracter,Cuvant,Caracter1).

caracter_cuvant(C):-member(C,[44,59,58,63,33,46,41,40,43,126]).

% am specificat codurile ASCII pentru , ; : ? ! . ) (

caractere_in_interiorul_unui_cuvant(C):-
	C>64,C<91;C>47,C<58;
	C==45;C==95;C>96,C<123.
caracter_numar(C):-C<58,C>=48.
