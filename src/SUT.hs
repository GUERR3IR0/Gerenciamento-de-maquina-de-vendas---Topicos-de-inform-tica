module SUT
    ( executarSUTCorreto
    ) where

import Types (Estado(..), Evento(..))

executarSUTCorreto :: [Evento] -> Maybe Estado
executarSUTCorreto eventos = executarEventos transicaoCorreta Ociosa eventos

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
