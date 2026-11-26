module SUT
    ( executarSUTCorreto
    , executarSUTComDefeito
    , executarSUTDefeitoEstoque
    ) where

import Types (Estado(..), Evento(..))

executarSUTCorreto :: [Evento] -> Maybe Estado
executarSUTCorreto eventos = executarEventos transicaoCorreta Ociosa eventos

executarSUTComDefeito :: [Evento] -> Maybe Estado
executarSUTComDefeito eventos = executarEventos transicaoComDefeito Ociosa eventos

executarSUTDefeitoEstoque :: [Evento] -> Maybe Estado
executarSUTDefeitoEstoque eventos = executarEventos transicaoDefeitoEstoque Ociosa eventos

executarEventos :: (Estado -> Evento -> Maybe Estado) -> Estado -> [Evento] -> Maybe Estado
executarEventos _ estado [] = Just estado
executarEventos transicao estado (evento:restantes) =
    case transicao estado evento of
        Nothing -> Nothing
        Just proximoEstado -> executarEventos transicao proximoEstado restantes

transicaoCorreta :: Estado -> Evento -> Maybe Estado
transicaoCorreta Ociosa InserirMoeda = Just ComCredito
transicaoCorreta ComCredito Cancelar = Just Ociosa
transicaoCorreta ComCredito SelecionarProduto = Just Dispensando
transicaoCorreta Dispensando ConfirmarEntrega = Just Ociosa
transicaoCorreta Dispensando EntregaUltimoItem = Just SemEstoque
transicaoCorreta SemEstoque ReporEstoque = Just Ociosa
transicaoCorreta _ _ = Nothing

transicaoComDefeito :: Estado -> Evento -> Maybe Estado
transicaoComDefeito ComCredito Cancelar = Just ComCredito
transicaoComDefeito estado evento = transicaoCorreta estado evento

transicaoDefeitoEstoque :: Estado -> Evento -> Maybe Estado
transicaoDefeitoEstoque SemEstoque ReporEstoque = Just SemEstoque
transicaoDefeitoEstoque estado evento = transicaoCorreta estado evento
