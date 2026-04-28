:- use_module(library(clpfd)).
:- use_module(library(lists)).
:- use_module(library(random)).

% ============================================================
% 1. DEFINICIÓN DE CARTAS
% ============================================================

% palo/1: define los palos de la baraja española.
palo(oro).
palo(copa).
palo(espada).
palo(basto).

% numero/1: define los números disponibles en la baraja española.
numero(1).
numero(2).
numero(3).
numero(4).
numero(5).
numero(6).
numero(7).
numero(10).
numero(11).
numero(12).

% carta/1: una carta se representa como Numero-Palo.
% Ejemplo: 1-espada, 7-oro, 12-copa.
carta(N-P) :-
    numero(N),
    palo(P).

% ============================================================
% 2. ESTADO DEL JUEGO CON DCG
% ============================================================

% El estado tendrá esta forma:
%
% [
%   jugadores([jugador(Nombre, Mano, Ganadas), ...]),
%   mazo(Cartas),
%   muestra(CartaMuestra),
%   turno(IndiceJugador),
%   mesa(CartasJugadas)
% ]

% estado//1: lee el estado actual sin modificarlo.
estado(E), [E] --> [E].

% estado//2: reemplaza un estado anterior por uno nuevo.
estado(E0, E), [E] --> [E0].

% ============================================================
% 3. INICIAR EL JUEGO
% ============================================================

% reiniciar//0: crea un mazo completo.
reiniciar -->
    estado(_, [mazo(Cartas)]),
    {
        setof(Carta, carta(Carta), Cartas)
    }.

% mezclar//0: mezcla las cartas del mazo.
mezclar -->
    estado(E0, E),
    {
        select(mazo(Cartas), E0, Resto),
        mezclar_cartas(Cartas, Mezcladas),
        E = [mazo(Mezcladas)|Resto]
    }.

% mezclar_cartas/2: mezcla una lista de cartas de forma aleatoria.
mezclar_cartas([], []).
mezclar_cartas(Cartas0, [Carta|Cartas]) :-
    length(Cartas0, N),
    random_between(1, N, I1),
    I is I1 - 1,
    nth0(I, Cartas0, Carta, Restantes),
    mezclar_cartas(Restantes, Cartas).

% crear_jugadores//1: agrega jugadores al estado.
crear_jugadores(Nombres) -->
    estado(E0, E),
    {
        maplist(jugador_vacio, Nombres, Jugadores),
        E = [
            jugadores(Jugadores),
            turno(0),
            mesa([])
            | E0
        ]
    }.

% jugador_vacio/2: crea un jugador sin cartas en mano ni cartas ganadas.
jugador_vacio(Nombre, jugador(Nombre, [], [])).

% ============================================================
% 4. REPARTO
% ============================================================

% tomar_carta//1: toma una carta del mazo.
tomar_carta(Carta) -->
    estado(E0, E),
    {
        select(mazo([Carta|RestoMazo]), E0, RestoEstado),
        E = [mazo(RestoMazo)|RestoEstado]
    }.



% repartir_tres//0: reparte tres cartas a cada jugador.
repartir_tres -->
    repartir_una_vuelta,
    repartir_una_vuelta,
    repartir_una_vuelta.

% repartir_una_vuelta//0: reparte una carta a cada jugador.
repartir_una_vuelta -->
    estado(E),
    {
        member(jugadores(Jugadores), E),
        length(Jugadores, Cantidad)
    },
    repartir_a_jugadores(0, Cantidad).

% repartir_a_jugadores//2: reparte una carta a cada jugador por índice.
repartir_a_jugadores(I, Cantidad) -->
    {
        I >= Cantidad
    }.

repartir_a_jugadores(I, Cantidad) -->
    {
        I < Cantidad
    },
    tomar_carta(Carta),
    dar_carta(I, Carta),
    {
        I1 is I + 1
    },
    repartir_a_jugadores(I1, Cantidad).

% dar_carta//2: agrega una carta a la mano de un jugador.
dar_carta(Indice, Carta) -->
    estado(E0, E),
    {
        select(jugadores(Jugadores0), E0, Resto),
        agregar_carta_a_jugador(Indice, Carta, Jugadores0, Jugadores),
        E = [jugadores(Jugadores)|Resto]
    }.

% agregar_carta_a_jugador/4: modifica la mano del jugador indicado.
agregar_carta_a_jugador(0, Carta,
    [jugador(Nombre, Mano, Ganadas)|Resto],
    [jugador(Nombre, [Carta|Mano], Ganadas)|Resto]).

agregar_carta_a_jugador(I, Carta, [J|Resto0], [J|Resto]) :-
    I > 0,
    I1 is I - 1,
    agregar_carta_a_jugador(I1, Carta, Resto0, Resto).

% ============================================================
% 5. JUGAR CARTAS
% ============================================================

% jugar_carta//2: un jugador juega una carta de su mano.
jugar_carta(IndiceJugador, Carta) -->
    estado(E0, E),
    {
        select(jugadores(Jugadores0), E0, Resto0), % Selecciona un jugador de la lista
        quitar_carta_a_jugador(IndiceJugador, Carta, Jugadores0, Jugadores), %% le quita una carta

        select(mesa(Mesa0), Resto0, Resto),
        Mesa = [jugada(IndiceJugador, Carta)|Mesa0],

        E = [jugadores(Jugadores), mesa(Mesa)|Resto]
    }.

% quitar_carta_a_jugador/4: elimina una carta de la mano de un jugador.
quitar_carta_a_jugador(0, Carta,
    [jugador(Nombre, Mano0, Ganadas)|Resto],
    [jugador(Nombre, Mano, Ganadas)|Resto]) :-
    select(Carta, Mano0, Mano).

quitar_carta_a_jugador(I, Carta, [J|Resto0], [J|Resto]) :-
    I > 0,
    I1 is I - 1,
    quitar_carta_a_jugador(I1, Carta, Resto0, Resto).

% ============================================================
% 6. JERARQUÍA DE CARTAS DEL TRUCO
% ============================================================

% valor_truco/2: asigna valor jerárquico a cada carta.
% Esta versión ignora piezas especiales de la muestra.
valor_truco(1-espada, 14).
valor_truco(1-basto, 13).
valor_truco(7-espada, 12).
valor_truco(7-oro, 11).
valor_truco(3-_, 10).
valor_truco(2-_, 9).
valor_truco(1-copa, 8).
valor_truco(1-oro, 8).
valor_truco(12-_, 7).
valor_truco(11-_, 6).
valor_truco(10-_, 5).
valor_truco(7-_, 4).
valor_truco(6-_, 3).
valor_truco(5-_, 2).
valor_truco(4-_, 1).

% gana_carta/2: verdadera si la primera carta le gana a la segunda.
gana_carta(Carta1, Carta2) :-
    valor_truco(Carta1, V1),
    valor_truco(Carta2, V2),
    V1 #> V2.

% ============================================================
% 7. GANADOR DE UNA BAZA
% ============================================================

% ganador_baza/2: obtiene el jugador ganador de las cartas en mesa.
ganador_baza([jugada(J, C)|Resto], Ganador) :-
    ganador_baza_(Resto, jugada(J, C), jugada(Ganador, _)).

% ganador_baza_/3: recorre la mesa conservando la mejor carta.
ganador_baza_([], Mejor, Mejor).

ganador_baza_([jugada(J, C)|Resto], jugada(_, MejorCarta), Ganador) :-
    gana_carta(C, MejorCarta),
    ganador_baza_(Resto, jugada(J, C), Ganador).

ganador_baza_([jugada(_, C)|Resto], Mejor, Ganador) :-
    Mejor = jugada(_, MejorCarta),
    \+ gana_carta(C, MejorCarta),
    ganador_baza_(Resto, Mejor, Ganador).

% finalizar_baza//0: calcula el ganador, le da las cartas y limpia la mesa.
finalizar_baza -->
    estado(E),
    {
        member(mesa(Mesa), E),
        ganador_baza(Mesa, Ganador)
    },
    juntar_mesa(Ganador).

% juntar_mesa//1: entrega las cartas de la mesa al jugador ganador.
juntar_mesa(Ganador) -->
    estado(E0, E),
    {
        select(mesa(Mesa), E0, Resto0),
        select(jugadores(Jugadores0), Resto0, Resto1),

        cartas_de_mesa(Mesa, Cartas),
        agregar_ganadas(Ganador, Cartas, Jugadores0, Jugadores),

        select(turno(_), Resto1, Resto),

        E = [
            jugadores(Jugadores),
            mesa([]),
            turno(Ganador)
            | Resto
        ]
    }.

% cartas_de_mesa/2: extrae las cartas de las jugadas.
cartas_de_mesa([], []).
cartas_de_mesa([jugada(_, Carta)|Resto], [Carta|Cartas]) :-
    cartas_de_mesa(Resto, Cartas).

% agregar_ganadas/4: suma cartas ganadas al jugador indicado.
agregar_ganadas(0, Cartas,
    [jugador(Nombre, Mano, Ganadas0)|Resto],
    [jugador(Nombre, Mano, Ganadas)|Resto]) :-
    append(Cartas, Ganadas0, Ganadas).

agregar_ganadas(I, Cartas, [J|Resto0], [J|Resto]) :-
    I > 0,
    I1 is I - 1,
    agregar_ganadas(I1, Cartas, Resto0, Resto).

% ============================================================
% 8. CREAR UNA PARTIDA COMPLETA
% ============================================================

% nueva_partida//1: crea una partida nueva con jugadores dados.
nueva_partida(Nombres) -->
    reiniciar,
    mezclar,
    crear_jugadores(Nombres),
    repartir_tres,
    definir_muestra.