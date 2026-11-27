-- Responsavel: Lucas. Contratos e decisoes: docs/decisoes-verifier.md.
module Verifier
    ( verificarCaso
    , executarSuite
    , gerarTestesNegativos
    , coberturaEstados
    , coberturaTransicoes
    ) where

import Data.List (nub)
import FSM (executarTransicao)
import Types

-- Nothing passa somente quando o caso espera rejeicao.
verificarCaso :: ([Evento] -> Maybe Estado) -> CasoDeTeste -> ResultadoExecucao
verificarCaso executarSUT caso =
    ResultadoExecucao
        { casoResultado = caso
        , estadoObtidoResultado = obtido
        , passouResultado = obtido == estadoEsperadoCaso caso
        }
  where
    obtido = executarSUT (eventosCaso caso)

-- Cada caso e enviado separadamente ao SUT, que reinicia no estado inicial.
-- Os resultados preservam a ordem dos casos recebidos.
executarSuite :: ([Evento] -> Maybe Estado) -> [CasoDeTeste] -> [ResultadoExecucao]
executarSuite executarSUT = map (verificarCaso executarSUT)

-- Para cada estado alcancavel, acrescenta a um caminho valido cada evento
-- declarado que nao possui transicao naquele estado. Requer FSM valida.
gerarTestesNegativos :: FSM -> [CasoDeTeste]
gerarTestesNegativos fsm =
    [ CasoDeTeste
        { descricaoCaso = "Rejeitar " ++ show evento ++ " em " ++ show estado
        , eventosCaso = caminho ++ [evento]
        , estadoEsperadoCaso = Nothing
        }
    | (estado, caminho) <- caminhosAteEstados fsm
    , evento <- nub (eventosFSM fsm)
    , executarTransicao fsm estado evento == Nothing
    ]

-- BFS interna apenas para preparar os estados dos testes negativos.
-- Nao gera suites All-States/All-Transitions, responsabilidade de Generator.
caminhosAteEstados :: FSM -> [(Estado, [Evento])]
caminhosAteEstados fsm = buscar [inicial] [(inicial, [])]
  where
    inicial = estadoInicialFSM fsm
    buscar _ [] = []
    buscar visitados ((estado, caminho):fila) =
        let novos =
                [ (destino, caminho ++ [evento])
                | destino <- nub
                    [destinoTransicao t | t <- transicoesFSM fsm,
                     origemTransicao t == estado]
                , destino `notElem` visitados
                , evento <- take 1
                    [eventoTransicao t | t <- transicoesFSM fsm,
                     origemTransicao t == estado, destinoTransicao t == destino]
                ]
        in (estado, caminho) :
            buscar (visitados ++ map fst novos) (fila ++ novos)

-- Cobertura estrutural no modelo, independente de o SUT passar ou falhar.
-- Requer FSM valida; estados declarados inalcancaveis entram no denominador.
coberturaEstados :: FSM -> [CasoDeTeste] -> Double
coberturaEstados _ [] = 0
coberturaEstados fsm casos =
    percentual (estadosFSM fsm)
        (concatMap (fst . percursoModelo fsm . eventosCaso) casos)

coberturaTransicoes :: FSM -> [CasoDeTeste] -> Double
coberturaTransicoes _ [] = 0
coberturaTransicoes fsm casos =
    percentual (transicoesFSM fsm)
        (concatMap (snd . percursoModelo fsm . eventosCaso) casos)

-- Conta o estado inicial ate com eventos vazios. Ao rejeitar um evento,
-- preserva o prefixo valido e nao processa os eventos restantes.
percursoModelo :: FSM -> [Evento] -> ([Estado], [Transicao])
percursoModelo fsm = percorrer (estadoInicialFSM fsm)
  where
    percorrer estado [] = ([estado], [])
    percorrer estado (evento:restantes) =
        case executarTransicao fsm estado evento of
            Nothing -> ([estado], [])
            Just destino ->
                let (estados, transicoes) = percorrer destino restantes
                in (estado : estados, Transicao estado evento destino : transicoes)

-- Sem elementos exigidos, nao ha obrigacoes pendentes (100%). A suite
-- vazia e tratada antes, nas funcoes publicas, e sempre tem cobertura 0%.
percentual :: Eq a => [a] -> [a] -> Double
percentual exigidos visitados =
    case nub exigidos of
        [] -> 100
        unicos ->
            100 * fromIntegral (length (filter (`elem` visitados) unicos))
                / fromIntegral (length unicos)
