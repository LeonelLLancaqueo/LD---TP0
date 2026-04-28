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


carta_ganadora(C1,C2, Carta_ganadora):-
    puntos_carta_truco(C1, Puntos1),
    puntos_carta_truco(C2, Puntos2),
    Puntos1 > Puntos2. 


%% cargo en el estado el conjunto de cartas posibles como lista
reiniciar -->
    estado(_, [mazo(Cartas)]),
    {
	setof(Carta, carta(Carta), Cartas)
    }.
mezclar_cartas -->
    estado(S0, S),
    {
	select(mazo(Cartas), S0, S1),
	mezclar(Cartas, Cartas_mezcladas),
	S = [stock(Cartas_mezcladas)|S1]
    }.

mezclar([], []).
mezclar(Xs0, [Y|Ys]) :-
    length(Xs0, N),
    random_integer(0, N, R),
    nth0(R, Xs0, Y, Xs),
    mezclar(Xs, Ys).


% [players([player(Name, PlayableCards, WonCards), player(Name, PlayableCards, WonCards), ...]), stock(Cards), trump(Trump)]

puntos_carta_truco(X,N):-
    carta(X),
    puntos_truco(X,N).


%defino los estados que atraviersa el juego
estado(E), [E] --> [E].
estado(E0, E), [E] --> [E0].

reiniciar -->
    estado(_, [mazo(Cartas)]),
    {
        setof(Carta, carta(Carta), Cartas)
    }.

% si uno gana la mano empieza en la siguiente ronda

%defino las 3 manos

% crear jugador- turno - mezclar cartas - repartir - jugar  

crear_jugador(N, player(N, [], [])).

crear_jugadores(Nombres) -->
    estado(S0, S),
    {
	same_length(Jugadores, nombres), % misma cantidad jugadores que nombres
	maplist(crear_jugador, Nombre, Jugadores), % creo para cada nombre el jugador
	S = [jugadores(Jugadores)|S0] % siguente estado con jugadores
    },
    barajar,
    barajar,
    barajar.    

barajar -->
    state(S0, S),
    {
	select(jugadores(Jugadores), S0, S1), 
	select(mazo(Cartas), S1, S2),
	barajar(Jugadores, Jugadores1, Cartas, Cartas1), % genero el nuevo estado de jugador y baraja
	S = [jugador(Jugadores1), mazo(Cartas1)|S2] % nuevo estado
    }.

barajar([], [], Cs, Cs).
barajar(Ps, Ps, [], []).
barajar([P|Ps], [P1|Ps1], [C|Cs], Cs1) :-
    P = player(N, A0, B0), % jugador estado actual
    P1 = player(N, [C|A0], B0), % jugador nuevo estado con una carta mas sacada del mazo.
    barajar(Ps, Ps1, Cs, Cs1).