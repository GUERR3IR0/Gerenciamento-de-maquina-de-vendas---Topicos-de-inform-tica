module Main (main) where

import Control.Monad (forM_, unless)
import Data.List (intercalate, transpose)
import FSM (errosFSM, validarFSM)
import Generator (gerarCasosDeTeste)
import Model (formatarTabelaModelo, maquinaVendasFSM)
import SUT (executarSUTComDefeito, executarSUTCorreto, executarSUTDefeitoEstoque)
import System.Environment (getArgs)
import System.Exit (die)
import System.IO (IOMode(WriteMode), hPutStr, hSetEncoding, utf8, withFile)
import System.IO.Error (tryIOError)
import Text.Printf (printf)
import Types
    ( CasoDeTeste(..)
    , CriterioCobertura(..)
    , Estado
    , Evento
    , FSM(..)
    , ResultadoExecucao(..)
    )
import Verifier
    ( coberturaEstados
    , coberturaTransicoes
    , executarSuite
    , gerarTestesNegativos
    )

main :: IO ()
main = do
    argumentos <- getArgs
    case argumentos of
        [] -> executarDemonstracao Nothing
        ["--relatorio", caminho] -> executarDemonstracao (Just caminho)
        ["--help"] -> putStrLn uso
        _ -> die uso

uso :: String
uso = "Uso de mbt-haskell\n  mbt-haskell [--relatorio ARQUIVO]\n  mbt-haskell --help"

executarDemonstracao :: Maybe FilePath -> IO ()
executarDemonstracao destino = do
    let fsm = maquinaVendasFSM
    unless (validarFSM fsm) $
        die (unlines ("FSM inválida" : errosFSM fsm))

    let relatorio = formatarRelatorio fsm
    putStr relatorio
    forM_ destino $ \caminho -> do
        resultado <- tryIOError $ withFile caminho WriteMode $ \arquivo -> do
            hSetEncoding arquivo utf8
            hPutStr arquivo relatorio
        either (die . ("Falha ao gravar o relatório\n" ++) . show) pure resultado

formatarRelatorio :: FSM -> String
formatarRelatorio fsm = unlines $
    [ "Teste Baseado em Modelos — Máquina de Vendas"
    , ""
    , "Modelo FSM validado"
    , "Estado inicial = " ++ show (estadoInicialFSM fsm)
    , "Estados = " ++ intercalate ", " (map show (estadosFSM fsm))
    , "Eventos = " ++ intercalate ", " (map show (eventosFSM fsm))
    , "Transições"
    ] ++ map ("  " ++) (lines (formatarTabelaModelo fsm))
      ++ concatMap (formatarSuite fsm) (suites fsm)

suites :: FSM -> [(String, [CasoDeTeste])]
suites fsm =
    [ ("All-States", gerarCasosDeTeste AllStates fsm)
    , ("All-Transitions", gerarCasosDeTeste AllTransitions fsm)
    , ("Testes negativos", gerarTestesNegativos fsm)
    ]

simuladores :: [(String, [Evento] -> Maybe Estado)]
simuladores =
    [ ("SUT correto", executarSUTCorreto)
    , ("SUT com defeito de cancelamento", executarSUTComDefeito)
    , ("SUT com defeito de estoque", executarSUTDefeitoEstoque)
    ]

formatarSuite :: FSM -> (String, [CasoDeTeste]) -> [String]
formatarSuite fsm (nome, casos) =
    [ ""
    , nome ++ " (" ++ show (length casos) ++ " casos)"
    , printf "  Cobertura no modelo | estados %.1f%% | transições %.1f%%"
        (coberturaEstados fsm casos) (coberturaTransicoes fsm casos)
    ] ++ map formatarResumo resultadosPorSUT
      ++ concat (zipWith formatarCaso casos resultadosPorCaso)
  where
    resultadosPorSUT =
        [(nomeSUT, executarSuite executarSUT casos) | (nomeSUT, executarSUT) <- simuladores]
    resultadosPorCaso = transpose
        [map ((,) nomeSUT) resultados | (nomeSUT, resultados) <- resultadosPorSUT]

formatarResumo :: (String, [ResultadoExecucao]) -> String
formatarResumo (nomeSUT, resultados) =
    "  " ++ nomeSUT ++ " | passaram " ++ show passaram ++ "/" ++ show total
        ++ " | falharam " ++ show (total - passaram)
  where
    passaram = length (filter passouResultado resultados)
    total = length resultados

formatarCaso :: CasoDeTeste -> [(String, ResultadoExecucao)] -> [String]
formatarCaso caso resultados =
    [ ""
    , "  " ++ descricaoCaso caso
    , "    Eventos = " ++ sequencia
    , "    Esperado = " ++ formatarEstado (estadoEsperadoCaso caso)
    ] ++ map formatarResultado resultados
  where
    sequencia = case eventosCaso caso of
        [] -> "(nenhum)"
        eventos -> intercalate " -> " (map show eventos)
    formatarResultado (nomeSUT, resultado) =
        "    " ++ nomeSUT ++ " | " ++ situacao resultado
            ++ " | obtido = " ++ formatarEstado (estadoObtidoResultado resultado)

formatarEstado :: Maybe Estado -> String
formatarEstado = maybe "Rejeição" show

situacao :: ResultadoExecucao -> String
situacao resultado
    | passouResultado resultado = "PASSOU"
    | otherwise = "FALHOU"
