module Model
    ( maquinaVendasFSM
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
