module Generator
    ( gerarTodosEstados
    , gerarTodasTransicoes
    , gerarCasosDeTeste
    ) where

import Types

caminhosAteEstados :: FSM -> [(Estado, [Evento])]
caminhosAteEstados fsm =
    buscar [(estadoInicialFSM fsm, [])]
           [estadoInicialFSM fsm]
  where
    buscar [] _ = []

    buscar ((estado, caminho):fila) visitados =
        let transicoes = filter
                (\t -> origemTransicao t == estado)
                (transicoesFSM fsm)

            adicionar (novos, vistos) t =
                let destino = destinoTransicao t
                    evento = eventoTransicao t
                in
                    if destino `elem` vistos
                    then (novos, vistos)
                    else
                        ( novos ++ [(destino, caminho ++ [evento])]
                        , vistos ++ [destino]
                        )

            (novos, visitadosAtualizados) =
                foldl adicionar ([], visitados) transicoes

        in (estado, caminho) :
           buscar (fila ++ novos) visitadosAtualizados

gerarTodosEstados :: FSM -> [CasoDeTeste]
gerarTodosEstados fsm =
    [ CasoDeTeste
        { descricaoCaso =
            "Alcancar estado " ++ show estado
        , eventosCaso = caminho
        , estadoEsperadoCaso = Just estado
        }
    | (estado, caminho) <- caminhosAteEstados fsm
    ]

gerarTodasTransicoes :: FSM -> [CasoDeTeste]
gerarTodasTransicoes fsm =
    [ CasoDeTeste
        { descricaoCaso =
            "Cobrir transicao "
            ++ show (origemTransicao t)
            ++ " -"
            ++ show (eventoTransicao t)
            ++ "-> "
            ++ show (destinoTransicao t)
        , eventosCaso = caminho ++ [eventoTransicao t]
        , estadoEsperadoCaso = Just (destinoTransicao t)
        }
    | t <- transicoesFSM fsm
    , Just caminho <- [caminhoAteEstado (origemTransicao t)]
    ]
  where
    caminhos = caminhosAteEstados fsm
    caminhoAteEstado estado = lookup estado caminhos

gerarCasosDeTeste :: CriterioCobertura -> FSM -> [CasoDeTeste]
gerarCasosDeTeste criterio fsm =
    case criterio of
        AllStates -> gerarTodosEstados fsm
        AllTransitions -> gerarTodasTransicoes fsm