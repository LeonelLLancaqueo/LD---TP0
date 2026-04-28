:- use_module(library(clpfd)).
%:- use_module(library(dcgs)).
:- use_module(library(lists)).
:- use_module(library(random)).

% -------- TRUCO -------------
%palo
palo(oro).
palo(copa).
palo(espada).
palo(basto).

% defino las cartas 
numero(12).
numero(11).
numero(10).
numero(7).
numero(6).
numero(5).
numero(4).
numero(3).
numero(2).
numero(1).

%defino carta numero y palo
carta(S-N):-
    numero(S),
    palo(N).

:- use_module(library(clpfd)).
%:- use_module(library(dcgs)).
:- use_module(library(lists)).
:- use_module(library(random)).
palo(oro).
palo(copa).
palo(espada).
palo(basto).

% defino las cartas 
numero(12).
numero(11).
numero(10).
numero(7).
numero(6).
numero(5).
numero(4).
numero(3).
numero(2).
numero(1).

%defino carta numero y palo
carta(S-N):-
    numero(S),
    palo(N).


% defino puntos del truco
% los puntos son por el nivel de la jerarquia... 
puntos_truco(1-espada, 13).
puntos_truco(1-basto, 12).
puntos_truco(7-espada, 11).
puntos_truco(7-oro, 10).
puntos_truco(3-_, 9).
puntos_truco(2-_, 8).
puntos_truco(1-copa, 7).
puntos_truco(1-oro, 7).
puntos_truco(12-_, 6).
puntos_truco(11-_, 5).
puntos_truco(10-_, 4).
puntos_truco(6-_, 3).
puntos_truco(5-_, 2).
puntos_truco(4-_, 1).


carta_ganadora(C1,C2):-
    puntos_carta_truco(C1, Puntos1),
    puntos_carta_truco(C2, Puntos2),
    Puntos1 > Puntos2. 


%% cargo en el estado el conjunto de cartas posibles como lista
reiniciar -->
    estado(_, [mazo(Cartas)]),
    {
	setof(Carta, carta(Carta), Cartas)
    }.

% phrase(reiniciar, [_], [Estado]).


%phrase(
%       mezclar_cartas,
%       [[mazo([1-oro, 2-copa, 3-espada])]],
%       [Estado]
%   ).
mezclar_cartas -->
    estado(S0, S),
    {
	select(mazo(Cartas), S0, S1),
	mezclar(Cartas, Cartas_mezcladas),
	S = [mazo(Cartas_mezcladas)|S1]
    }.

mezclar([], []).
mezclar(Xs0, [Y|Ys]) :-
    length(Xs0, N),
    N1 is N - 1,
    random_between(0, N1, R),
    nth0(R, Xs0, Y, Xs),
    mezclar(Xs, Ys).


% [players([player(Name, PlayableCards, WonCards), player(Name, PlayableCards, WonCards), ...]), stock(Cards), trump(Trump)]

puntos_carta_truco(X,N):-
    carta(X),
    puntos_truco(X,N).


%defino los estados que atraviersa el juego
estado(S), [S] --> [S].
estado(S0, S), [S] --> [S0].



% si uno gana la mano empieza en la siguiente ronda

%defino las 3 manos

% crear jugador- turno - mezclar cartas - repartir - jugar  
% jugador (nombre, cartas, mano_ganadas)
crear_jugador(N, jugador(N, [], [])).

crear_jugadores(Nombres) -->
    estado(S0, S),
    {
	same_length(Jugadores, Nombres), % misma cantidad jugadores que nombres
	maplist(crear_jugador, Nombres, Jugadores), % creo para cada nombre el jugador
	S = [jugadores(Jugadores)|S0] % siguente estado con jugadores
    }.
    
barajar_rondas -->      
    barajar_a_jugador,
	barajar_a_jugador,
	barajar_a_jugador.

barajar -->
    estado(S0, S),
    {
	select(jugadores(Jugadores), S0, S1), 
	select(mazo(Cartas), S1, S2),
	barajar(Jugadores, Jugadores1, Cartas, Cartas1), % genero el nuevo estado de jugador y baraja
	S = [jugadores(Jugadores1), mazo(Cartas1)|S2] % nuevo estado
    }.

barajar_a_jugador([], [], Cs, Cs).
barajar_a_jugador(Ps, Ps, [], []).
barajar_a_jugador([P|Ps], [P1|Ps1], [C|Cs], Cs1) :-
    P = jugador(N, A0, B0), % jugador estado actual
    P1 = jugador(N, [C|A0], B0), % jugador nuevo estado con una carta mas sacada del mazo.
    barajar_a_jugador(Ps, Ps1, Cs, Cs1).

%%phrase(
%%       (
%%           reiniciar,
%%           mezclar_cartas,
%%           crear_jugadores([leonel, daniela]),
%%       	 barajar_rondas
%%       ),
%%       [[]],
%%       [Estado]
%%   ).


%% DIVIDIR EN 3 RONDAS||  1 JUGADOR JUEGA UNA CARTA -> 1 JUGADOR GANA -> ASIGNO PUNTO --> MEZCLA --> SIGUIE SIGUIENTE RONDA --> MIENTRAS 2 RONDAS



jugar_rondas -->  %% CORREGIR _ DEFINIR RESTRICCION DE QUE NINGUN JUGADOR GANO MAS DE 1 MANO
	jugadores(P, P),
    { P = [player(_, _, X)|_], X > 1} %% un jugador gano mas de una mano   
jugar_rondas -->
    jugadores(P, P),
    { P = [player(_, _, X)|_], X < 2 }, %% ninguno gano mas de 2 manos
    jugar_ronda,
    jugar_rondas.

jugar_ronda -->
    state(S),
    players(P0, P2),
    {
	member(trump(Trump), S),
	format("Brisca round~nTrump is: ~a~n~n", [Trump])
    },
    play_players(P0, Cards),
    {
	round_winner(Cards, Trump, WinnerCard),
	maplist(remove_card, P0, Cards, P1),
	nth0(N, Cards, WinnerCard),
	nth0(N, P1, WinnerPlayer0),
	append(PBefore, [WinnerPlayer0|PAfter], P1),
	WinnerPlayer0 = player(WinnerName, C, W0),
	format("Winner card is ~w from ~w~n", [WinnerCard, WinnerName]),
	append(W0, Cards, W1),
	append([player(WinnerName, C, W1)|PAfter], PBefore, P2)
    },
    barajar_a_jugador.

quitar_carta(P0, C, P) :-
    P0 = jugador(N, C0, W),
    select(C, C0, C1),
    P = jugador(N, C1, W).

jugar_jugadores([], []) --> [].
jugar_jugadores([P|Ps], [C|Cs]) -->
    {
	P = jugador(Name, SelectableCards, _),
	format("It's ~a's turn!~n", [Name]),
	format("Selectable cards: ~w~n", [SelectableCards]),
	read(C),
	member(C, SelectableCards)
    },
    jugar_jugadores(Ps, Cs).