module Main where

import Control.Monad (unless)
import Data.List (nub)
import FSM (executarSequencia, validarFSM)
import Model (maquinaVendasFSM)
import SUT
import Types
import Verifier

main :: IO ()
main = do
    let fsm = maquinaVendasFSM
        visitar = [InserirMoeda, SelecionarProduto, EntregaUltimoItem]
        casoEstados = CasoDeTeste "Visitar todos os estados" visitar (Just SemEstoque)
        cancelar = CasoDeTeste "Cancelar" [InserirMoeda, Cancelar] (Just Ociosa)
        confirmar = CasoDeTeste "Confirmar entrega"
            [InserirMoeda, SelecionarProduto, ConfirmarEntrega] (Just Ociosa)
        repor = CasoDeTeste "Repor estoque"
            [InserirMoeda, SelecionarProduto, EntregaUltimoItem, ReporEstoque] (Just Ociosa)
        vazio = CasoDeTeste "Somente iniciar" [] (Just Ociosa)
        rejeitado = CasoDeTeste "Cancelar sem credito" [Cancelar] Nothing
        credito = CasoDeTeste "Inserir moeda" [InserirMoeda] (Just ComCredito)
        casos = [cancelar, repor, vazio, credito]
        completa = [casoEstados, cancelar, confirmar, repor]
        negativos = gerarTestesNegativos fsm
        rejeitadoAposMoeda = CasoDeTeste "Rejeitar e parar"
            [InserirMoeda, ReporEstoque, SelecionarProduto] Nothing
        semTransicoes = FSM [Ociosa] [Cancelar] [] Ociosa
        ciclo = FSM [Ociosa] [InserirMoeda, Cancelar]
            [Transicao Ociosa InserirMoeda Ociosa] Ociosa
        desconectado = FSM [Ociosa, SemEstoque] [ReporEstoque]
            [Transicao SemEstoque ReporEstoque SemEstoque] Ociosa
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
            , ("modelos usados nos testes sao validos",
                all validarFSM [fsm, semTransicoes, ciclo, desconectado])
            , ("18 negativos distintos com rejeicao esperada",
                length negativos == 18
                && length (nub (map eventosCaso negativos)) == 18
                && all ((== Nothing) . estadoEsperadoCaso) negativos)
            , ("cada negativo prepara um prefixo valido e depois e rejeitado",
                all (prefixoValido fsm) negativos
                && all ((== Nothing) . executarSequencia fsm . eventosCaso) negativos)
            , ("SUT correto passa todos os negativos",
                all passouResultado (executarSuite executarSUTCorreto negativos))
            , ("visita a todos os estados cobre 100% de estados e 50% de transicoes",
                coberturaEstados fsm [casoEstados] == 100
                && coberturaTransicoes fsm [casoEstados] == 50)
            , ("suite completa cobre estados e transicoes",
                coberturaEstados fsm completa == 100
                && coberturaTransicoes fsm completa == 100)
            , ("repeticoes nao aumentam cobertura",
                coberturaTransicoes fsm [casoEstados, casoEstados] == 50)
            , ("suite vazia tem 0% de cobertura",
                coberturaEstados fsm [] == 0 && coberturaTransicoes fsm [] == 0)
            , ("sequencia vazia conta apenas o estado inicial",
                coberturaEstados fsm [vazio] == 25
                && coberturaTransicoes fsm [vazio] == 0)
            , ("rejeicao no inicio conta apenas o estado inicial",
                coberturaEstados fsm [rejeitado] == 25
                && coberturaTransicoes fsm [rejeitado] == 0)
            , ("prefixo valido e preservado e sufixo apos rejeicao e ignorado",
                coberturaEstados fsm [rejeitadoAposMoeda] == 50
                && abs (coberturaTransicoes fsm [rejeitadoAposMoeda] - 100 / 6) < 1e-9)
            , ("sem transicoes: 100% com caso e 0% sem casos",
                coberturaTransicoes semTransicoes [vazio] == 100
                && coberturaTransicoes semTransicoes [] == 0)
            , ("BFS termina em ciclo e nao duplica preparacao",
                map eventosCaso (gerarTestesNegativos ciclo) == [[Cancelar]])
            , ("estado inalcancavel nao gera preparacao impossivel",
                map eventosCaso (gerarTestesNegativos desconectado) == [[ReporEstoque]])
            , ("inalcancaveis continuam exigidos nas metricas",
                coberturaEstados desconectado [vazio] == 50
                && coberturaTransicoes desconectado [vazio] == 0)
            ]
    mapM_ conferir checagens
    putStrLn (show (length checagens) ++ " verificacoes passaram.")

conferir :: (String, Bool) -> IO ()
conferir (nome, passou) = do
    unless passou (ioError (userError ("FALHOU: " ++ nome)))
    putStrLn ("OK: " ++ nome)

prefixoValido :: FSM -> CasoDeTeste -> Bool
prefixoValido fsm caso =
    case eventosCaso caso of
        [] -> False
        eventos -> executarSequencia fsm (init eventos) /= Nothing
