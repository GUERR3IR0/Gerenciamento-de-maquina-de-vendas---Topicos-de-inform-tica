module Main (main) where

import Control.Monad (forM_, unless)
import FSM (errosFSM, validarFSM)
import Generator (gerarCasosDeTeste)
import Model (formatarTabelaModelo, maquinaVendasFSM)
import SUT (executarSUTComDefeito, executarSUTCorreto, executarSUTDefeitoEstoque)
import System.Exit (die)
import Types
    ( CasoDeTeste(..)
    , CriterioCobertura(..)
    , Estado
    , Evento
    , FSM(..)
    , ResultadoExecucao(..)
    )
import Verifier (executarSuite, gerarTestesNegativos)

main :: IO ()
main = do
    let fsm = maquinaVendasFSM
    unless (validarFSM fsm) $
        die (unlines ("FSM inválida" : errosFSM fsm))

    putStrLn "Teste Baseado em Modelos — Máquina de Vendas"
    putStrLn ("Estado inicial = " ++ show (estadoInicialFSM fsm))
    putStrLn ("Estados = " ++ show (estadosFSM fsm))
    putStrLn ("Eventos = " ++ show (eventosFSM fsm))
    putStrLn "Transições"
    putStr (formatarTabelaModelo fsm)

    forM_ (suites fsm) $ \(nome, casos) -> do
        putStrLn ("\n" ++ nome)
        forM_ casos $ \caso ->
            putStrLn ("  " ++ descricaoCaso caso ++ " | " ++ show (eventosCaso caso)
                ++ " | esperado = " ++ show (estadoEsperadoCaso caso))
        forM_ simuladores $ \(nomeSUT, executarSUT) -> do
            putStrLn ("  " ++ nomeSUT)
            forM_ (executarSuite executarSUT casos) $ \resultado ->
                putStrLn ("    " ++ descricaoCaso (casoResultado resultado)
                    ++ " | obtido = " ++ show (estadoObtidoResultado resultado)
                    ++ " | " ++ situacao resultado)

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

situacao :: ResultadoExecucao -> String
situacao resultado
    | passouResultado resultado = "PASSOU"
    | otherwise = "FALHOU"
