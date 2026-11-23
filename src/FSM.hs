module FSM
    ( executarTransicao
    , executarSequencia
    , executarSequenciaComRastro
    , estadosAlcancaveis
    , buscarEstadosAlcancaveis
    , validarFSM
    , errosFSM
    ) where

import Data.List (nub)
import qualified Data.Sequence as Seq
import Data.Sequence (Seq((:<|)))
import Types

executarTransicao :: FSM -> Estado -> Evento -> Maybe Estado
executarTransicao fsm estado evento =
    case [destinoTransicao t
         | t <- transicoesFSM fsm
         , origemTransicao t == estado
         , eventoTransicao t == evento] of
        destino:_ -> Just destino
        [] -> Nothing

executarSequencia :: FSM -> [Evento] -> Maybe Estado
executarSequencia fsm = foldl avancar (Just (estadoInicialFSM fsm))
  where
    avancar Nothing _ = Nothing
    avancar (Just estado) evento = executarTransicao fsm estado evento

executarSequenciaComRastro :: FSM -> [Evento] -> Maybe (Estado, [PassoExecucao])
executarSequenciaComRastro fsm eventos =
    case percorrer (estadoInicialFSM fsm) eventos [] of
        Just (estado, passos) -> Just (estado, reverse passos)
        Nothing -> Nothing
  where
    percorrer estado [] passos =
        Just (estado, passos)
    percorrer estado (evento:restantes) passos =
        case executarTransicao fsm estado evento of
            Nothing ->
                Nothing
            Just destino ->
                percorrer destino restantes
                    (PassoExecucao estado evento (Just destino) : passos)

-- Mantem a busca em largura com dependencia apenas da biblioteca base.
estadosAlcancaveis :: FSM -> [Estado]
estadosAlcancaveis fsm =
    bfs (Seq.singleton (estadoInicialFSM fsm)) [estadoInicialFSM fsm]
  where
    bfs Seq.Empty visitados = nub visitados
    bfs (estado :<| restantes) visitados =
        let destinos = nub
                [destinoTransicao t
                | t <- transicoesFSM fsm
                , origemTransicao t == estado]
            novos = [destino | destino <- destinos, destino `notElem` visitados]
        in bfs (restantes <> Seq.fromList novos) (visitados ++ novos)

buscarEstadosAlcancaveis :: FSM -> [Estado]
buscarEstadosAlcancaveis = estadosAlcancaveis

errosFSM :: FSM -> [String]
errosFSM fsm =
    concat
        [ ["O estado inicial nao pertence ao conjunto de estados."]
          | estadoInicialFSM fsm `notElem` estadosFSM fsm
        ]
    ++ ["Estado de origem inexistente: " ++ show (origemTransicao t)
        | t <- transicoesFSM fsm
        , origemTransicao t `notElem` estadosFSM fsm]
    ++ ["Estado de destino inexistente: " ++ show (destinoTransicao t)
        | t <- transicoesFSM fsm
        , destinoTransicao t `notElem` estadosFSM fsm]
    ++ ["Evento inexistente: " ++ show (eventoTransicao t)
        | t <- transicoesFSM fsm
        , eventoTransicao t `notElem` eventosFSM fsm]
    ++ ["Transicao duplicada para o mesmo estado e evento: "
        ++ show (origemTransicao t) ++ " -"
        ++ show (eventoTransicao t)
        | t <- transicoesFSM fsm
        , length [u | u <- transicoesFSM fsm
                    , origemTransicao u == origemTransicao t
                    , eventoTransicao u == eventoTransicao t] > 1]

validarFSM :: FSM -> Bool
validarFSM fsm = null (errosFSM fsm)
