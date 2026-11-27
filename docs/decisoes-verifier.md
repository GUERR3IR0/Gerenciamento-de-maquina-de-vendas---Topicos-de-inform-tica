# Decisões do verificador e integração dos testes

Registro de 26 de novembro de 2026. A parte de Lucas é `src/Verifier.hs`.
O guia exige duas entregas lógicas: verificação de casos e suítes; depois
negativos e métricas. Esta primeira entrega implementa `verificarCaso` e
`executarSuite`, com testes e a migração do resultado esperado.

A documentação local de referência é `docs/visao-geral.md` e
`docs/model-pedro.md`. Lucas autorizou nesta conversa a alteração compartilhada
em `src/Types.hs` para permitir a representação de rejeições. Essa autorização
é específica; os módulos dos demais integrantes mantêm suas responsabilidades.

## Resultado esperado com rejeição explícita

Antes, `estadoEsperadoCaso :: Estado` só representava um término válido.
O SUT de Bruno e a FSM de Victor retornam `Nothing` quando um evento é inválido.
Não era possível representar esse resultado esperado sem inventar um estado
ou esconder uma convenção na descrição do teste.

Agora o campo é `estadoEsperadoCaso :: Maybe Estado`:

- `Just estado` espera sucesso naquele estado final.
- `Nothing` espera rejeição da sequência.

`verificarCaso` compara diretamente os resultados obtido e esperado.
Uma rejeição só passa quando foi explicitamente esperada. A descrição é apenas
texto de exibição. `executarSuite` mantém a ordem dos casos e chama o SUT
separadamente para cada sequência, reiniciando a simulação.

```haskell
CasoDeTeste "Cancelar compra" [InserirMoeda, Cancelar] (Just Ociosa)
CasoDeTeste "Rejeitar cancelamento sem credito" [Cancelar] Nothing
```

## Migração dos consumidores

Quem construir casos válidos deve trocar `estadoEsperadoCaso = estado` por
`estadoEsperadoCaso = Just estado`; isso também vale para o último argumento
do construtor posicional. O futuro `Generator.hs` e os casos manuais do futuro
`Main.hs` devem seguir esse contrato. Valores serializados por `Show` mudam
de formato. Esses módulos ainda não estão presentes, portanto sua integração
não foi validada.

## Validação da primeira entrega

Na raiz do repositório:

```powershell
ghc -isrc -Wall -Werror -fno-code src/Types.hs src/FSM.hs src/Model.hs src/SUT.hs src/Verifier.hs
runghc -isrc tests/VerifierSpec.hs
```

São conferidos os resultados corretos, a detecção dos dois defeitos do SUT,
rejeições esperadas e inesperadas, ordem, independência e suíte vazia.
A geração de negativos, as métricas e o registro de suas convenções ficam
para a segunda entrega. Nenhum push foi realizado.
