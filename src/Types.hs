module Types
    ( Estado(..)
    , Evento(..)
    , Transicao(..)
    , FSM(..)
    , CasoDeTeste(..)
    , CriterioCobertura(..)
    , ResultadoExecucao(..)
    , PassoExecucao(..)
    ) where

data Estado
    = Ociosa
    | ComCredito
    | Dispensando
    | SemEstoque
    deriving (Eq, Ord, Read, Show)

data Evento
    = InserirMoeda
    | Cancelar
    | SelecionarProduto
    | ConfirmarEntrega
    | EntregaUltimoItem
    | ReporEstoque
    deriving (Eq, Ord, Read, Show)

data Transicao = Transicao
    { origemTransicao :: Estado
    , eventoTransicao :: Evento
    , destinoTransicao :: Estado
    }
    deriving (Eq, Ord, Read, Show)

data FSM = FSM
    { estadosFSM :: [Estado]
    , eventosFSM :: [Evento]
    , transicoesFSM :: [Transicao]
    , estadoInicialFSM :: Estado
    }
    deriving (Eq, Ord, Read, Show)

data CasoDeTeste = CasoDeTeste
    { descricaoCaso :: String
    , eventosCaso :: [Evento]
    , estadoEsperadoCaso :: Estado
    }
    deriving (Eq, Ord, Read, Show)

data CriterioCobertura
    = AllStates
    | AllTransitions
    deriving (Eq, Ord, Read, Show)

data ResultadoExecucao = ResultadoExecucao
    { casoResultado :: CasoDeTeste
    , estadoObtidoResultado :: Maybe Estado
    , passouResultado :: Bool
    }
    deriving (Eq, Ord, Read, Show)

data PassoExecucao = PassoExecucao
    { estadoAntes :: Estado
    , eventoExecutado :: Evento
    , estadoDepois :: Maybe Estado
    }
    deriving (Eq, Ord, Read, Show)
