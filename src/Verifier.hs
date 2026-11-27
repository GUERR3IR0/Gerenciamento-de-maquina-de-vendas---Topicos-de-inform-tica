-- Responsavel: Lucas. Contratos e decisoes: docs/decisoes-verifier.md.
module Verifier
    ( verificarCaso
    , executarSuite
    ) where

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
