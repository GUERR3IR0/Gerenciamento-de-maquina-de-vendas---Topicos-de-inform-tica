module Main where

import Control.Monad (unless)
import SUT
import Types
import Verifier

main :: IO ()
main = do
    let cancelar = CasoDeTeste "Cancelar" [InserirMoeda, Cancelar] (Just Ociosa)
        repor = CasoDeTeste "Repor estoque"
            [InserirMoeda, SelecionarProduto, EntregaUltimoItem, ReporEstoque] (Just Ociosa)
        vazio = CasoDeTeste "Somente iniciar" [] (Just Ociosa)
        rejeitado = CasoDeTeste "Cancelar sem credito" [Cancelar] Nothing
        credito = CasoDeTeste "Inserir moeda" [InserirMoeda] (Just ComCredito)
        casos = [cancelar, repor, vazio, credito]
        checagens =
            [ ("SUT correto passa os casos validos", all passouResultado (executarSuite executarSUTCorreto casos))
            , ("defeito de cancelamento e detectado", not (passouResultado (verificarCaso executarSUTComDefeito cancelar)))
            , ("defeito de estoque e detectado", not (passouResultado (verificarCaso executarSUTDefeitoEstoque repor)))
            , ("rejeicao esperada passa", passouResultado (verificarCaso executarSUTCorreto rejeitado))
            , ("aceitacao indevida falha no negativo", not (passouResultado (verificarCaso (const (Just Ociosa)) rejeitado)))
            , ("rejeicao inesperada falha no positivo", not (passouResultado (verificarCaso (const Nothing) cancelar)))
            , ("suite preserva casos e ordem", map casoResultado (executarSuite executarSUTCorreto casos) == casos)
            , ("resultado registra o estado obtido", estadoObtidoResultado (verificarCaso executarSUTCorreto credito) == Just ComCredito)
            , ("casos sao independentes", all passouResultado (executarSuite executarSUTCorreto [credito, vazio, credito]))
            , ("suite vazia nao tem resultados", null (executarSuite executarSUTCorreto []))
            ]
    mapM_ conferir checagens
    putStrLn (show (length checagens) ++ " verificacoes passaram.")

conferir :: (String, Bool) -> IO ()
conferir (nome, passou) = do
    unless passou (ioError (userError ("FALHOU: " ++ nome)))
    putStrLn ("OK: " ++ nome)
