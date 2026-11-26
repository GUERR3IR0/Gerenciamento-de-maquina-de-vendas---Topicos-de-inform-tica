module Model
    ( maquinaVendasFSM
    , formatarTabelaModelo
    , exportarDot
    ) where

import Types

maquinaVendasFSM :: FSM
maquinaVendasFSM = FSM
    { estadosFSM =
        [ Ociosa
        , ComCredito
        , Dispensando
        , SemEstoque
        ]
    , eventosFSM =
        [ InserirMoeda
        , Cancelar
        , SelecionarProduto
        , ConfirmarEntrega
        , EntregaUltimoItem
        , ReporEstoque
        ]
    , transicoesFSM =
        [ Transicao Ociosa      InserirMoeda      ComCredito
        , Transicao ComCredito  Cancelar          Ociosa
        , Transicao ComCredito  SelecionarProduto Dispensando
        , Transicao Dispensando ConfirmarEntrega  Ociosa
        , Transicao Dispensando EntregaUltimoItem SemEstoque
        , Transicao SemEstoque  ReporEstoque      Ociosa
        ]
    , estadoInicialFSM = Ociosa
    }

formatarTabelaModelo :: FSM -> String
formatarTabelaModelo fsm = unlines (map formatarLinha (transicoesFSM fsm))
  where
    formatarLinha t =
        show (origemTransicao t)
        ++ " --" ++ show (eventoTransicao t) ++ "--> "
        ++ show (destinoTransicao t)

exportarDot :: FSM -> String
exportarDot fsm = unlines (["digraph MaquinaDeVendas {"] ++ map formatarSeta (transicoesFSM fsm) ++ ["}"])
  where
    formatarSeta t =
        "  " ++ show (origemTransicao t)
        ++ " -> " ++ show (destinoTransicao t)
        ++ " [label=\"" ++ show (eventoTransicao t) ++ "\"];"
