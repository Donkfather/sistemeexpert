
:-use_module(library(lists)).
:-use_module(library(system)).
:-use_module(library(file_systems)).
:-op(900,fy,not).
:-dynamic fapt/3.
:-dynamic interogat/1.
:-dynamic scop/1.
:-dynamic interogabil/3.
:-dynamic regula/3.
:-discontiguous citeste_cuvant/3.
:-dynamic stream/1.
:-dynamic java/1.

%  #############################################    COMMUNICATION    ################################################3

:-use_module(library(sockets)).

% flash output curata buffer-ul. trebuie apelat imediat dupa un write.
inceput:-format('Salutare\n',[]),	flush_output,
				prolog_flag(argv, [PortSocket|_]), %preiau numarul portului, dat ca argument cu -a
				% portul este atom, nu constanta numerica, asa ca trebuie sa il convertim la numar
				% trebuie transformat portul din string in int
				atom_chars(PortSocket,LCifre),
				number_chars(Port,LCifre),%transforma lista de cifre in numarul din 
				
				% aici se deschiide conexiunea spre interfata pe localhost si portul obtinut
				% se scrie si se citeste pe acelasi stream si se trimite text
				socket_client_open(localhost: Port, Stream, [type(text)]),
				
				% asta citeste si procezeaza cate o comanda
				proceseaza_text_primit(Stream,0).
				
				
proceseaza_text_primit(Stream,C):-
				% citim de pe stream (trebuie sa pui punct dupa fiecare comanda)
				read(Stream,CevaCitit),
				proceseaza_termen_citit(Stream,CevaCitit,C).
				
% C numara numarul de comenzi date(incepe de la 0 mai sus)		

proceseaza_termen_citit(Stream, X, _):-
				(X == end_of_file ; X == exit),
				close(Stream).	

proceseaza_termen_citit(Stream,salut,C):-
				% daca am citit salut, se intra pe ramura asta si raspunde cu salut bre
				write(Stream,'salut, bre!\n'),
				flush_output(Stream),
				C1 is C+1,
				proceseaza_text_primit(Stream,C1).
				
proceseaza_termen_citit(Stream,'ce mai faci?',C):-
				write(Stream,'ma plictisesc...\n'),
				flush_output(Stream),
				C1 is C+1,
				proceseaza_text_primit(Stream,C1).
				
proceseaza_termen_citit(Stream, X + Y,C):-
				Rez is X+Y,
				write(Stream,Rez),nl(Stream),
				flush_output(Stream),
				C1 is C+1,
				proceseaza_text_primit(Stream,C1).
				
oras(bucuresti, mare).				
oras(pitesti, mic).
proceseaza_termen_citit(Stream, oras(X),C):-
				oras(X,Tip),
				format(Stream,'~p este un oras ~p\n',[X,Tip]),
				flush_output(Stream),
				C1 is C+1,
				proceseaza_text_primit(Stream,C1).
				
				
proceseaza_termen_citit(Stream, comanda(pornire), C):-		
				pornire,
				flush_output(Stream),
				C1 is C + 1,
				proceseaza_text_primit(Stream, C1)
				.
				
proceseaza_termen_citit(Stream, comanda(incarca(F)), C):-
				incarca(Stream, F),
				flush_output(Stream),
				C1 is C + 1,
				proceseaza_text_primit(Stream, C1)
				.

proceseaza_termen_citit(Stream, comanda(consulta), C):-
				executa([consulta], Stream),
				flush_output(Stream),
				C1 is C + 1,
				proceseaza_text_primit(Stream, C1)
				.
			
proceseaza_termen_citit(Stream, Altceva,C):-
				write(Stream,'nu inteleg ce vrei sa spui: '),write(Stream,Altceva),nl(Stream),
				flush_output(Stream),
				C1 is C+1,
				proceseaza_text_primit(Stream,C1).



%  #############################################    COMMUNICATION    ################################################3


tab(N) :- N>0,N1 is N-1, write(' '), tab(N1).
tab(0).

tab(N, Fisier) :- N>0,N1 is N-1, write(Fisier, ' '), tab(N1, Fisier).
tab(0, Fisier).

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

% asta primeste istorictul cu indice de intrebari sau 'utiliz' daca a raspuns user-ul
lista_float_int([],[]).
% daca regula este diferita de 'utiliz' (adica daca e numar), converteste float to int (ca sa nu afiseze regula 2.0, ci regula 2)
% daca este 'utiliz' atunci regula ramane neschimbata
lista_float_int([Regula|Reguli],[Regula1|Reguli1]):-
	(Regula \== utiliz,   
	Regula1 is integer(Regula);
	Regula ==utiliz, Regula1=Regula),
	lista_float_int(Reguli,Reguli1).

pornire :-
	retractall(interogat(_)),
	retractall(fapt(_, _, _)),
	repeat,
	write('Introduceti una din urmatoarele optiuni: '),
	nl,nl,
	write(' (Incarca Consulta Reinitiaza  Afisare_fapte  Cum   Iesire) '),
	nl,nl,write('|: '),citeste_linie([H | T]),
	write('done retract'), nl,
	executa([H | T]), H == iesire.

	
executa([incarca]) :- 
	incarca,!,nl, % predicatul incarca citeste fisierul. Cut-ul e pus ca sa nu mai treaca la celelalte optiuni
	write('Fisierul dorit a fost incarcat'),nl.
executa([consulta]) :- 
	scopuri_princ,!.
executa([consulta], Stream) :-
	scopuri_princ(Stream),!.
% asta face clear la tot ce am obtinut din sistemul expert (raspuns de la user sau fapte)
executa([reinitiaza]) :- 
	retractall(interogat(_)),
	retractall(fapt(_,_,_)),!.
executa([afisare_fapte]) :-
	afiseaza_fapte,!.
executa([cum|L]) :- cum(L),!.
executa([iesire]):-!.  % aici se termina programult
executa([_|_]) :- 		% aici prinde orice alt caz de comanda incorecta.
	write('Comanda incorecta! '),nl.

% Apeleaza mai intai scop(Atr) - aici se salveaza scopul S expert 
% dupa determina(Atr) - realizaeaza scopul
/*
scopuri_princ :- 
	% open('F:/NgenH/Projects/Prolog/ExempluInterfataProlog/my_project/log_witcher3/log.txt', write, Fisier),
	% open('C:/Users/Izabela/Desktop/prologProiect/sisteme-expert/my_project/log_witcher3/log.txt', write, Fisier),
	open('C:/Users/AlexandruFlorian/Desktop/Sisteme expert/sisteme-expert/my_project/log_witcher3/log.txt', write, Fisier),
	assert(stream(Fisier)),
	scop(Atr),determina(Atr, Fisier),
	setof(str(FC, Atr, Val), Gen^fapt(av(Atr, Val), FC, Gen), L),
	list_rev(L, Reversed),
	afiseaza_scop_lista(Reversed),
	scrie_demonstratie_fisier(Reversed),
	close(Fisier),
	retractall(stream(_))
	.
scopuri_princ :-
	stream(F), close(F),
	retractall(stream(_)),
	write('Nu exista solutii'), nl.
*/

scopuri_princ(Stream) :-
	% open('F:/NgenH/Projects/Prolog/ExempluInterfataProlog/my_project/log_witcher3/log.txt', write, Fisier),
	% open('C:/Users/Izabela/Desktop/prologProiect/sisteme-expert/my_project/log_witcher3/log.txt', write, Fisier),
	open('C:/Users/AlexandruFlorian/Desktop/Sisteme expert/sisteme-expert/my_project/log_witcher3/log.txt', write, Fisier),
	assert(stream(Fisier)),
	scop(Atr),
	determina(Atr, Fisier, Stream),
	setof(str(FC, Atr, Val), Gen^fapt(av(Atr, Val), FC, Gen), L),
	list_rev(L, Reversed),
	afiseaza_scop_lista(Reversed, Stream),
	scrie_demonstratie_fisier(Reversed),
	close(Fisier),
	retractall(stream(_))
	.
scopuri_princ(Stream) :-
	stream(F), close(F),
	retractall(stream(_)),
	write('Nu exista solutii'), nl.

list_rev([],[]). 
list_rev([H|T],Li):- list_rev(T,RevT), append(RevT,[H],Li).

scrie_demonstratie_fisier(Reversed):-
	Reversed = [str(FC, Atr, Val) | T],     
	% A = 'C:/Users/Izabela/Desktop/prologProiect/sisteme-expert/my_project/log_witcher3/demonstatie_personaj=',
	A = 'C:/Users/AlexandruFlorian/Desktop/Sisteme expert/sisteme-expert/my_project/log_witcher3/demonstatie_personaj=',
	atom_concat(A, Val, B),
	atom_concat(B, '.txt', Path),
	open(Path, write, FisierDem),
	tell(FisierDem),
	cum([Atr, '%', '%', Val]),
	told,
	scrie_demonstratie_fisier(T)
	.
scrie_demonstratie_fisier([]).

determina(Atr) :-
	realizare_scop(av(Atr,_),_,[scop(Atr)]),!.
% aici trebuie sa facem un caz de nu are solutii
determina(_).

determina(Atr, Fisier) :- 
	realizare_scop(av(Atr,_), _, [scop(Atr)], Fisier),!.
% aici trebuie sa facem un caz de nu are solutii
determina(_, Fisier).

determina(Atr, Fisier, Stream) :- 
	realizare_scop(av(Atr,_), _, [scop(Atr)], Fisier, Stream),
	nl(Stream), flush_output(Stream), !.
% aici trebuie sa facem un caz de nu are solutii
determina(_, Fisier, Stream).

afiseaza_scop(Atr) :-
	fapt(av(Atr,Val),FC,_),
	FC >= 20,scrie_scop(av(Atr,Val),FC),
	nl,fail.
afiseaza_scop(_):- nl,nl.

afiseaza_scop_lista([str(FC, Atr, Val) | T]) :-
	FC >= 20,write(Atr), write('  '), write(Val), write('  '),
	write('  '), write(FC),
	nl,afiseaza_scop_lista(T).
afiseaza_scop_lista([]):- nl,nl.

afiseaza_scop_lista([str(FC, Atr, Val) | T], Stream) :-
	FC >= 20,
	write(Stream, Atr), write(Stream, ' '),
	write(Stream, Val), write(Stream, ' '),
	write(Stream, FC), write(Stream, '\n'), flush_output(Stream),
	write(Atr), write('  '), write(Val), write('  '),
	write('  '), write(FC),

	afiseaza_scop_lista(T, Stream).
afiseaza_scop_lista([], Stream):- write(Stream, '\n'), flush_output(Stream).

scrie_scop(av(Atr,Val),FC) :- 
	transformare(av(Atr,Val), X),
	scrie_lista(X),tab(2),
	write(' '),
	write('factorul de certitudine este '),
	FC1 is integer(FC),write(FC1).

% primul parametru este de structura not av(atr, valoare)
% apeleaza realizare_scop pentru a afla FC si ii pune un minus in fata :-?
realizare_scop(not Scop,Not_FC,Istorie, Fisier) :-
	realizare_scop(Scop,FC,Istorie, Fisier),
	Not_FC is - FC, !.
realizare_scop(not Scop,Not_FC,Istorie, Fisier, Stream) :-
	realizare_scop(Scop,FC,Istorie, Fisier, Stream),
	Not_FC is - FC, !.
	
% mai intai se uita daca scopul a fost deja obtinut
% daca nu a fost, atunci incearca sa il obtina si cauta ceva interogabil
realizare_scop(Scop,FC,_, Fisier) :-
	fapt(Scop,FC,_), !.
realizare_scop(Scop,FC,_, Fisier, Stream) :-
	fapt(Scop,FC,_), !.

realizare_scop(Scop,FC,Istorie, Fisier) :- 
	pot_interoga(Scop,Istorie, Fisier),
	!,realizare_scop(Scop,FC,Istorie, Fisier).  % dupa ce am itnerogat, incerc iar sa satisfac scopul
realizare_scop(Scop,FC,Istorie, Fisier, Stream) :-
	pot_interoga(Scop,Istorie, Fisier, Stream), 
	!,realizare_scop(Scop,FC,Istorie, Fisier, Stream).  % dupa ce am itnerogat, incerc iar sa satisfac scopul

% aici satisafem scopul. fg este pentru cazul in care avem deja reguli pentru a deduce valoarea atributului din regula
realizare_scop(Scop,FC_curent,Istorie, Fisier) :-
	fg(Scop,FC_curent,Istorie, Fisier).
realizare_scop(Scop,FC_curent,Istorie, Fisier, Stream) :-
	fg(Scop,FC_curent,Istorie, Fisier, Stream).
	
% ne luam regula, premisele si concluzia. N = id-ul regulii
% demonstreaza primeste toate datele din regula si calculeaza Istoria
fg(Scop,FC_curent,Istorie, Fisier) :-
	regula(N, premise(Lista), concluzie(Scop,FC)),
	demonstreaza(N,Lista,FC_premise,Istorie, Fisier),
	ajusteaza(FC,FC_premise,FC_nou),
	actualizeaza(Scop,FC_nou,FC_curent,N),  % asta e pentru cazult in care avem mai multe reguli pentru acelasi atribut
	FC_curent == 100,!.
fg(Scop,FC,_, _) :- fapt(Scop,FC,_).

fg(Scop,FC_curent,Istorie, Fisier, Stream) :-
	regula(N, premise(Lista), concluzie(Scop,FC)),
	demonstreaza(N,Lista,FC_premise,Istorie, Fisier, Stream),
	ajusteaza(FC,FC_premise,FC_nou),
	actualizeaza(Scop,FC_nou,FC_curent,N),  % asta e pentru cazult in care avem mai multe reguli pentru acelasi atribut
	FC_curent == 100,!.
fg(Scop,FC,_, Fisier, Stream) :- fapt(Scop,FC,_).

% verifica daca nu a fost pusa intrebare si daca nu e asa, atunci pot sa pun
% dupa ce interogheazsa, face un assert ca sa stie ca a pus deja intrebarea
pot_interoga(av(Atr,_),Istorie, Fisier) :-
	not interogat(av(Atr,_)),
	interogabil(Atr,Optiuni,Mesaj),
	interogheaza(Atr,Mesaj,Optiuni,Istorie, Fisier),	
	asserta( interogat(av(Atr,_)) ).
pot_interoga(av(Atr,_),Istorie, Fisier, Stream) :-
	not interogat(av(Atr,_)),
	interogabil(Atr,Optiuni,Mesaj),
	interogheaza(Atr,Mesaj,Optiuni,Istorie, Fisier, Stream),
	asserta( interogat(av(Atr,_)) ).


cum([]) :- write('Scop? '),nl,
	write('|:'),citeste_linie(Linie),nl,
	transformare(Scop,Linie), cum(Scop).
% asta face la fel ca mai sus, dar ii zice direct si scopul, nu mai asteapta sa fie intrebat
cum(L) :- 
	transformare(Scop,L),nl, cum(Scop).
% asta verifica daca exista un fapt in baza de cunostine pentru Scop, si are si FC si istoric (tinut in Reguli)
cum(not Scop) :- 
	fapt(Scop,FC,Reguli),
	lista_float_int(Reguli,Reguli1),
	FC < -20,transformare(not Scop,PG),  % daca FC este mai mare decat 20 (e cu -  pentru ca are not) apeleaza transformare
	append(PG,[a,fost,derivat,cu, ajutorul, 'regulilor: '|Reguli1],LL),  % aici modificam partea din istorie a regulilor si obtine LL
	scrie_lista(LL),nl,afis_reguli(Reguli),fail. 
% asta e la fel ca mai sus, doar ca nu are not
cum(Scop) :-
	fapt(Scop,FC,Reguli),
	lista_float_int(Reguli,Reguli1),
	FC > 20, transformare(Scop,PG), 
	append(PG,[a,fost,derivat,cu, ajutorul, 'regulilor: '|Reguli1],LL),
	scrie_lista(LL),nl,afis_reguli(Reguli),
	fail.
	% cum de orice ca sa se termine cu success
cum(_).

% pentru subpunctul f, aici trebuie modificat 
afis_reguli([]).
% aici primeste istoricul. ia indicele si apeleaza afis_regula(N) de unde ia regula, premisele si concluzia
% si mai jos putem modifica formatul
afis_reguli([N|X]) :-
	afis_regula(N),
	premisele(N),
	afis_reguli(X).
afis_regula(N) :-
	% primul parametru este ........
	regula(	N, premise(Lista_premise),concluzie(Scop, FC)),
	NN is integer(N),
	scrie_lista(['regula  %% ',NN]),
	transformare(Scop,Scop_tr),
	FC1 is integer(FC), Scop_tr = [Nume, _, _, Val],
	scrie_lista([Nume, ' %% ', Val, ' factor certitudine %% ', FC1]),
	scrie_lista(['enum conditii [']),
	scrie_lista_premise(Lista_premise),
	write(']'),nl.
	
afis_regula(N, Fisier) :- 
	% primul parametru este ........
	regula(	N, premise(Lista_premise),concluzie(Scop, FC)),
	NN is integer(N),
	scrie_lista(['regula  %% ',NN, ' \n'], Fisier),
	transformare(Scop,Scop_tr), Scop_tr = [Nume, _, _, Val],
	FC1 is integer(FC),
	scrie_lista([Nume,' %% ', Val, ' factor certitudine %% ', FC1, '\n'], Fisier),
	scrie_lista(['enum conditii [\n'], Fisier),
	scrie_lista_premise(Lista_premise, Fisier),
	write(Fisier, ']\n\n\n')
	%, nl
	.

scrie_lista_premise([]).
scrie_lista_premise([H|T]) :-
	transformare(H,H_tr),
	tab(5),scrie_lista(H_tr),
	scrie_lista_premise(T).
	
scrie_lista_premise([], Fisier).
scrie_lista_premise([H|T], Fisier) :-
	transformare(H,H_tr),
	tab(5, Fisier),scrie_lista(H_tr, Fisier), write(Fisier, '\n'),
	scrie_lista_premise(T, Fisier).

transformare(av(A,da),[A]) :- !.
transformare(not av(A,da), [not,A]) :- !.
transformare(av(A,nu),[not,A]) :- !.
transformare(av(A,V),[A,'%','%',V]).

% aici face o afisare arborescenta
premisele(N) :-
	regula(N, premise(Lista_premise), _),
	!, cum_premise(Lista_premise).
	
cum_premise([]).
cum_premise([Scop|X]) :-
	cum(Scop),
	cum_premise(X).
	
% ne afiseaza mesajul, (aici trebuie sa trimitem pe Stream, ca sa ajunga in interfata grafica)
% primul interogheaza este pentru da|nu
interogheaza(Atr,Mesaj,[da,nu],Istorie, Fisier) :-
	scrie_log(Atr, Istorie, Fisier),
	!,write(Mesaj),nl,
	de_la_utiliz(X,Istorie,[da,nu]),
	det_val_fc(X,Val,FC),
	asserta( fapt(av(Atr,Val),FC,[utiliz]) ).  % utiliz = istoric (asa a zis Iza)
% asta e pentru valori multiple
interogheaza(Atr,Mesaj,Optiuni,Istorie, Fisier) :-
	scrie_log(Atr, Istorie, Fisier),
	write(Mesaj),nl,   % afiseaza mesajul
	citeste_opt(VLista,Optiuni,Istorie),
	assert_fapt(Atr,VLista).  % asta adauga faptul
	
interogheaza(Atr,Mesaj,[da,nu],Istorie, Fisier, Stream) :-
	scrie_log(Atr, Istorie, Fisier),
	!,write(Stream, Mesaj),nl, write(Stream, '\n'), flush_output(Stream),
	de_la_utiliz(X,Istorie,[da,nu], Stream),
	det_val_fc(X,Val,FC),
	asserta( fapt(av(Atr,Val),FC,[utiliz]) ).  % utiliz = istoric (asa a zis Iza)
interogheaza(Atr,Mesaj,Optiuni,Istorie, Fisier, Stream) :-
	scrie_log(Atr, Istorie, Fisier),
	write(Stream, Mesaj),nl,   % afiseaza mesajul
	citeste_opt(VLista,Optiuni,Istorie, Stream),
	assert_fapt(Atr,VLista).  % asta adauga faptul
	
scrie_log(Atr, Istorie, Fisier):-
	write(Fisier, Atr), write(Fisier, '\n'), 
	\+ proceseaza_raspuns([de_ce], Istorie, _, Fisier),
	flush_output(Fisier)
	.

% aici se afiseaza optiunile. ia o patanteza, face append la optiuni, si dupa inchid paranteza, dupa care ia input de la user
citeste_opt(X,Optiuni,Istorie) :-
	append(['('],Optiuni,Opt1),
	append(Opt1,[')'],Opt),
	scrie_lista(Opt),
	de_la_utiliz(X,Istorie,Optiuni).
citeste_opt(X,Optiuni,Istorie, Stream) :-
	append(['('],Optiuni,Opt1),
	append(Opt1,[')'],Opt),
	scrie_lista(Opt, Stream),
	de_la_utiliz(X,Istorie,Optiuni, Stream).

% asta primeste raspunsul de la utilizator 
% afiseaza un prompt si apeleaza citeste_linie
% verificam daca user-ul a dat una din optiunile bune
de_la_utiliz(X,Istorie,Lista_opt) :-
	repeat,write(': '), citeste_linie(X),
	proceseaza_raspuns(X,Istorie,Lista_opt).
de_la_utiliz(X,Istorie,Lista_opt, Stream) :-
	repeat, read(Stream, X), write('am citit'),nl,write(X),nl, write(Lista_opt), nl,
	proceseaza_raspuns(X,Istorie,Lista_opt), write('success'), nl.

% prima clauza este [de_ce]. adica daca sunt intrebat o chestie, pot sa il intreb de ce ai nevoie de informatia aia
% deci daca scriu [de_ce], imi afiseaza istoria pentru acest atribut
% ca sa il oprim de tot putem adauga o noua clauza gen asta cu de_ce in care sa ii zicem opreste si sa dam doar fail
proceseaza_raspuns([de_ce],Istorie,_, Fisier) :-
	nl,afis_istorie(Istorie, Fisier),
	!,fail.

proceseaza_raspuns([de_ce],Istorie,_, Fisier, Stream) :-
	write('suint in proc rasp'),
	afis_istorie(Istorie, Fisier, Stream),
	!,fail.
	
afis_istorie([], Fisier) :- nl.
afis_istorie([scop(X)|T], Fisier) :-
	scrie_lista([scop,X], Fisier),!,
	afis_istorie(T, Fisier).
afis_istorie([N|T], Fisier) :-
	afis_regula(N, Fisier),!,afis_istorie(T, Fisier).
	
% daca ajungem aici, inseamna ca avem un raspuns de la user si verificam daca raspunsul se afla in lista optiunilor
proceseaza_raspuns([X],_,Lista_opt):-
	member(X,Lista_opt).
% daca in raspuns user-ul da si FC, acesta este luat in considerare si suprascrie FC initial al atributului
proceseaza_raspuns([X,fc,FC],_,Lista_opt):-
	member(X,Lista_opt),float(FC).

assert_fapt(Atr,[Val,fc,FC]) :-
	!,asserta( fapt(av(Atr,Val),FC,[utiliz]) ).
assert_fapt(Atr,[Val]) :-
	asserta( fapt(av(Atr,Val),100,[utiliz])).

% daca nu are FC, ii pune -100 default (pentru ca e preactiv negativul (nu da) == (not))
% daca l-a pus, il ia
% sau intra pe aia cu valori multiple
% la final pune default 100 pentru da
det_val_fc([nu],da,-100).
det_val_fc([nu,FC],da,NFC) :- NFC is -FC.
det_val_fc([nu,fc,FC],da,NFC) :- NFC is -FC.
det_val_fc([Val,FC],Val,FC).
det_val_fc([Val,fc,FC],Val,FC).
det_val_fc([Val],Val,100).
	
afis_istorie([]) :- nl.
afis_istorie([scop(X)|T]) :-
	scrie_lista([scop,X]),!,
	afis_istorie(T).
afis_istorie([N|T]) :-
	afis_regula(N),!,afis_istorie(T).

% o sa ia pe rand premisele si o sa le calculeze valoarea. Ori intreaba, ori deduce din alte reguli
demonstreaza(N,ListaPremise,Val_finala,Istorie, Fisier) :-
	dem(ListaPremise,100,Val_finala,[N|Istorie], Fisier),!.

demonstreaza(N,ListaPremise,Val_finala,Istorie, Fisier, Stream) :-
	dem(ListaPremise,100,Val_finala,[N|Istorie], Fisier, Stream),!.

% asta  e predicat recursiv pentru ca trebuie sa parcurga o lista de listeaza_fapte
% avem pasul de oprire
% in Val_finala se calculeaza factorul de certitudine final
dem([],Val_finala,Val_finala,_, _).
dem([H|T],Val_actuala,Val_finala,Istorie, Fisier) :-
	realizare_scop(H,FC,Istorie, Fisier),   % de aici se intoare cu un FC si un Istoric
	Val_interm is min(Val_actuala,FC),  % face minimul dintre FC cu care a pornit si valoarea actolo
	Val_interm >= 20,
	dem(T,Val_interm,Val_finala,Istorie, Fisier).  % se apeleaza recursiv dem cu restul premiselor

dem([],Val_finala,Val_finala,_, _, _).
dem([H|T],Val_actuala,Val_finala,Istorie, Fisier, Stream) :-
	realizare_scop(H,FC,Istorie, Fisier, Stream),   % de aici se intoare cu un FC si un Istoric
	Val_interm is min(Val_actuala,FC),  % face minimul dintre FC cu care a pornit si valoarea actolo
	Val_interm >= 20,
	dem(T,Val_interm,Val_finala,Istorie, Fisier, Stream).  % se apeleaza recursiv dem cu restul premiselor
 
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
	file_exists(F), !, incarca_prolog(F).  % daca exista fisierul si e totul okey, il incarca
incarca :-
	write('Nume incorect de fisier! '),nl,fail.
	
incarca_prolog( Path) :-
	retractall(interogat(_)),retractall(fapt(_, _, _)),
	retractall(scop(_)),retractall(interogabil(_, _, _)),
	retractall(regula(_, _, _)),
	atom_concat(Path, '/my_rules.txt', Rules),
	atom_concat(Path, '/log_witcher3', Directory), 
	((\+ directory_exists(Directory), make_directory(Directory)) ; true),
	see(Rules),incarca_reguli(Path), seen, !. % see citeste din fisier. seen inchide fisierul
	

% interograt si fapt a explicat deja cica
% scop memoreaza atributul scop
% interogabil memoreaza intrebarile. primul parametru este atributul. al doilea e lista de optiuni. al treilea este intrebarea in sine
incarca(Stream, Path) :-
	retractall(interogat(_)),retractall(fapt(_, _, _)),
	retractall(scop(_)),retractall(interogabil(_, _, _)),
	retractall(regula(_, _, _)),
	atom_concat(Path, '/my_rules.txt', Rules),
	atom_concat(Path, '/log_witcher3', Directory), 
	((\+ directory_exists(Directory), make_directory(Directory)) ; true),
	see(Rules),incarca_reguli, seen, !. % see citeste din fisier. seen inchide fisierul
	
incarca(Stream, _):-
	write(Stream, 'eroare_incarcare\n')
	.

incarca_reguli :-
	repeat, citeste_propozitie(L),    % citeste linie citea pana la \n. citeste propozitie citeste pana la .
	proceseaza(L), L == [end_of_file], nl.  % proceseaza e cel care interpreteaza informatia citita

proceseaza([end_of_file]):-!.  % daca sunt la final, pa
proceseaza(L) :-
	% fiecare propozitie se transforma intr-un fapt
	% trad: in R pune faptul pe care trebuie sa il assertam 
	% foloseste assertz pentru a le pune fix in ordinea in care sunt citite
	trad(R,L,[]),
%	write(R), nl,
	assertz(R), !. 
	
% reguli DCG  - reguli speciale de parsare
% predicat care face propozitii de tip: subiect predicat complement
% articol + subs = subiect; predicat = verb; complement = prepozitie + substantiv
% deci trad asta stie ca daca ii vine o propozitie de genul scopul este [ceva], atunci [ceva] e returnat in X
% scop(X) este R-ul de mai sus. Deci R este scop de X daca trad se descompune in 'scopul este ............'
trad(scop(X)) --> [scop, '%', '%', X].
trad(scop(X)) --> [scop, X].
trad(interogabil(Atr, M, P)) --> 
	% daca este intrebare:
	% intreaba atributul cu o lista de optiuni si mesajul de afisare
	[intrebare, '[', Atr, ';'], afiseaza(Atr, P), lista_optiuni(M).
% trad (ID, [per(atribut, val) ....], 'Atunci [concluzie] fc [F]')
trad(regula(N, premise(Daca), concluzie(Atunci, F))) --> 
	identificator(N), atunci(Atunci, F), daca(Daca).
trad('Eroare la parsare' - L, L, _).

% lista_optiuni de descompune in cuvantul optiuni si paranteza
% lista_de_optiuni itereaza prin optiuni
% cat timp lista nu se unifica cu [element, ')'], se citeste
% recursiv.
lista_optiuni(M) --> [variante,':', '['],lista_de_optiuni(M).
lista_de_optiuni([Element]) -->  [Element,']', ']'].
lista_de_optiuni([Element|T]) --> [Element, ';'], lista_de_optiuni(T).

afiseaza(_, P) -->  [text, ':', P, ';'].
afiseaza(P, P) -->  [].
% asta ia ID-ul unei reguli
identificator(N) --> [regula, nr, '%', '%', N].

% asta ia partea ca daca din premise si ia toata premizele
daca(Daca) --> lista_premise(Daca).

% se opreste cand intalnesti termenul atunci, altfel
% ia premizele, le baga in lista si apeleaza recursiv
lista_premise([Daca]) --> propoz(Daca).

% pot pune premize cu si sau cu , intre ele
% propz ia prima pereche de atribut valoare si ia lista premizelor
% lista_premise([Prima|Celalalte]) --> propoz(Prima),[']', ',', '['],lista_premise(Celalalte).
lista_premise([Prima|Celalalte]) --> propoz(Prima),[','],lista_premise(Celalalte).

% atunci merge pana gaseste factorul de certitudine
atunci(Atunci, FC) --> propoz(Atunci), [fact, certitudine, '%', '%'], [FC], [enum, conditii].
% daca lipsteste factorul de certitudine, il pune automat 100
atunci(Atunci, 100) --> propoz(Atunci), [enum, conditii].

% asta ia bucatile din premize de tipul 
% not ceva
% ceva este altceva
% ceva
propoz(not av(Atr,da)) --> [not, Atr].  % il memoreaza ca fiind not(Atr, da). Puteam sa il memoram si ca (Atr, nu).
propoz(av(Atr,Val)) --> [Atr, '%', '%', Val].  % valori multiple ale atributului
propoz(av(Atr,da)) --> [Atr].
propoz(av(Atr,Val)) --> ['[', Atr, '%', '%', Val, ']'].
propoz(not av(Atr,da)) --> ['[', not, Atr, ']'].  
propoz(av(Atr,da)) --> ['[', Atr, ']'].

citeste_linie([Cuv | Lista_cuv]) :-
	get_code(Car),
	citeste_cuvant(Car, Cuv, Car1), 
	rest_cuvinte_linie(Car1, Lista_cuv). 
      
% -1 este codul ASCII pt EOF

rest_cuvinte_linie(-1, []):- !.    
rest_cuvinte_linie(Car,[]) :- (Car==13;Car==10), !.
rest_cuvinte_linie(Car,[Cuv1|Lista_cuv]) :-
	citeste_cuvant(Car,Cuv1,Car1),      
	rest_cuvinte_linie(Car1,Lista_cuv).

citeste_propozitie([Cuv | Lista_cuv]) :-
	get_code(Car), citeste_cuvant(Car, Cuv, Car1), % citeste un cuvant si apeleaza rest_cuvinte_propozitie
	rest_cuvinte_propozitie(Car1, Lista_cuv). 
     
% aici suntem in fisier, deci daca citim -1, atunci suntem la EOF
rest_cuvinte_propozitie(-1, []):- !.    
rest_cuvinte_propozitie(Car, []) :- Car == 46, !. % daca e punct, returnam lista vida pentru ca e finalul propozitiei
rest_cuvinte_propozitie(Car,[Cuv1|Lista_cuv]) :-   % altfel pun caracterul in lista si continui citirea de caractere
	citeste_cuvant(Car,Cuv1,Car1),      
	rest_cuvinte_propozitie(Car1,Lista_cuv).

citeste_cuvant(-1, end_of_file, -1):- !.
citeste_cuvant(Caracter, Cuvant, Caracter1) :-   
	caracter_cuvant(Caracter), !, 
	name(Cuvant, [Caracter]), get_code(Caracter1).
citeste_cuvant(Caracter, Numar, Caracter1) :-
	caracter_numar(Caracter), !,
	citeste_tot_numarul(Caracter, Numar, Caracter1). 

citeste_tot_numarul(Caracter,Numar,Caracter1):-
	determina_lista(Lista1,Caracter1),
	append([Caracter],Lista1,Lista),
	transforma_lista_numar(Lista,Numar).

determina_lista(Lista,Caracter1):-
	get_code(Caracter), 
	(caracter_numar(Caracter),
	determina_lista(Lista1, Caracter1),
	append([Caracter], Lista1, Lista); 
	\+(caracter_numar(Caracter)),
	Lista=[],Caracter1 = Caracter). 

transforma_lista_numar([], 0).
transforma_lista_numar([H|T], N):-
	transforma_lista_numar(T, NN), 
	lungime(T, L), Aux is 10**L,
	HH is H-48,N is HH*Aux+NN.

lungime([],0).
lungime([_|T],L):-
	lungime(T,L1),
	L is L1+1.

% 39 este codul ASCII pt '

citeste_cuvant(Caracter, Cuvant, Caracter1):-
	Caracter == 39, !,
	pana_la_urmatorul_apostrof(Lista_caractere),
	L = [Caracter|Lista_caractere],
	name(Cuvant, L), get_code(Caracter1).        

pana_la_urmatorul_apostrof(Lista_caractere):-
	get_code(Caracter),
	(Caracter == 39,Lista_caractere=[Caracter];
	Caracter\==39,
	pana_la_urmatorul_apostrof(Lista_caractere1),
	Lista_caractere=[Caracter|Lista_caractere1]).

citeste_cuvant(Caracter, Cuvant, Caracter1):-          
	caractere_in_interiorul_unui_cuvant(Caracter),!,              
	((Caracter > 64, Caracter < 91), !,
	Caracter_modificat is Caracter + 32;
	Caracter_modificat is Caracter),                              
	citeste_intreg_cuvantul(Caractere, Caracter1), % optinem o lisat de coduri ascii
	name(Cuvant, [Caracter_modificat | Caractere]).  % transforma lista de coduri ascii in atom      

citeste_intreg_cuvantul(Lista_Caractere, Caracter1):-
	get_code(Caracter),  %citim un caracter
	(caractere_in_interiorul_unui_cuvant(Caracter), % verificam ca e caracter valid
	((Caracter > 64, Caracter < 91),!,  % daca e litera mare, il facem litera mica
	Caracter_modificat is Caracter + 32;
	Caracter_modificat is Caracter),
	citeste_intreg_cuvantul(Lista_Caractere1, Caracter1),  % apeleaza recursiv
	Lista_Caractere = [Caracter_modificat | Lista_Caractere1];
	\+ (caractere_in_interiorul_unui_cuvant(Caracter)), % daca nu e caracter valid, oprim recursivitatea
	Lista_Caractere = [], Caracter1 = Caracter).

% daca nu intra pe niciunul din celelalte cazuri, sare peste caracter
citeste_cuvant(_, Cuvant, Caracter1):-                
	get_code(Caracter),       
	citeste_cuvant(Caracter, Cuvant, Caracter1). 

% am specificat codurile ASCII pentru , ; : ? ! . ) (
% aici specificam ce alte caractere mai pot fi luate ca un cuvant intreg
% 91 = [   
% 93 = ]
% 37 = %
% 44 = ,
% 59 = ;
% 46 = .
caracter_cuvant(C):-member(C, [44, 59, 58, 63, 33, 46, 41, 40, 37, 91, 93]).

caractere_in_interiorul_unui_cuvant(C):-
	C > 64, C < 91; C > 47, C < 58;
	C == 45; C == 95; C > 96, C < 123.
caracter_numar(C):- C < 58, C >= 48.