# Decisões do verificador e integração dos testes

Registro de 26 de novembro de 2026. A parte de Lucas é `src/Verifier.hs`.
O guia exige duas entregas lógicas: verificação de casos e suítes; depois
negativos e métricas. As duas estão implementadas, com testes e a migração do
resultado esperado.

A documentação local de referência é `docs/visao-geral.md` e
`docs/model-pedro.md`. Lucas autorizou nesta conversa a alteração compartilhada
em `src/Types.hs` para permitir a representação de rejeições e a adoção das
regras de cobertura abaixo. São decisões posteriores autorizadas por Lucas,
e não regras originalmente detalhadas no guia. Essa autorização é específica;
os módulos dos demais integrantes mantêm suas responsabilidades.

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

## Geração dos testes negativos

O verificador usa uma BFS interna para encontrar um caminho mínimo válido
desde o estado inicial até cada estado alcançável. Para cada caminho, acrescenta
um evento declarado em `eventosFSM` que não tenha transição naquele estado.
O resultado esperado é `Nothing`. Na Máquina de Vendas são 18 casos negativos:
4 estados vezes 6 eventos, menos as 6 transições válidas.

Cada estado é preparado uma vez, inclusive quando existem ciclos ou várias
arestas chegando ao mesmo destino. Empates entre caminhos mínimos seguem a
ordem das transições no modelo. Estados inalcançáveis não recebem testes
negativos, pois não é possível preparar o SUT neles a partir do estado inicial.

Essa busca serve somente para preparar testes negativos, responsabilidade de
Lucas. Ela não implementa as suítes All-States ou All-Transitions do Gustavo.
Não há importação de `Generator`, nem suposição sobre a ordem de seus casos.

## Regras de cobertura

As métricas medem a cobertura estrutural das sequências no modelo, e não a
porcentagem de testes aprovados nem o caminho real de um SUT defeituoso.
O resultado esperado do caso não modifica o percurso usado na métrica.

Para cada métrica, calcula-se `100 * visitados distintos / exigidos distintos`.
Os exigidos são todos os estados ou transições declarados, inclusive os
inalcançáveis. Repetir casos, estados ou transições não aumenta a cobertura.

| Situação | Comportamento e motivo |
|---|---|
| Suíte vazia | 0% em ambas as métricas: nenhum caso foi executado. Essa regra tem prioridade sobre a ausência de transições. |
| Caso com eventos vazios | Visita o estado inicial e nenhuma transição: a simulação foi iniciada. |
| Evento inválido | Preserva os estados e transições do prefixo válido e encerra naquele ponto, acompanhando a rejeição da FSM e do SUT. |
| Modelo sem transições e suíte não vazia | 100% de transições: não há transições exigidas que faltem exercitar. |

As funções que recebem uma FSM pressupõem um modelo estruturalmente válido;
o programa principal deve chamar `validarFSM` antes. Modelos inválidos não têm
uma política de recuperação definida por este contrato.

O percurso parcial é calculado dentro do `Verifier.hs` com `executarTransicao`.
Não se alterou `executarSequenciaComRastro`, porque ela pertence a Victor e
descarta o rastro quando ocorre uma rejeição.

## Contratos públicos

```haskell
executarSuite :: ([Evento] -> Maybe Estado) -> [CasoDeTeste] -> [ResultadoExecucao]
gerarTestesNegativos :: FSM -> [CasoDeTeste]
coberturaEstados :: FSM -> [CasoDeTeste] -> Double
coberturaTransicoes :: FSM -> [CasoDeTeste] -> Double
```

As assinaturas acima seguem o guia. Também é exportada `verificarCaso`, para
verificar um caso individual. O SUT mantém seu contrato existente.

## Limites da verificação

O SUT retorna somente um estado final ou `Nothing`. Quando retorna `Nothing`,
não informa em qual passo rejeitou a sequência. Portanto, um teste negativo
não consegue distinguir uma rejeição correta no último evento de uma rejeição
indevida durante a preparação. Essa limitação já existe no contrato do SUT;
resolvê-la exigiria outro alinhamento entre os integrantes.

O `Generator.hs` ainda não estava presente quando essas alterações foram
implementadas. É possível validar o verificador com casos manuais e com seus
próprios negativos; a integração com as suítes reais do Gustavo fica pendente
até a chegada do módulo e a migração para `Maybe Estado`.

## Validação reproduzível

Na raiz do repositório:

```powershell
ghc -isrc -Wall -Werror -fno-code src/Types.hs src/FSM.hs src/Model.hs src/SUT.hs src/Verifier.hs
runghc -isrc tests/VerifierSpec.hs
```

São conferidos os resultados corretos, a detecção dos dois defeitos do SUT,
rejeições esperadas e inesperadas, ordem, independência, geração dos 18
negativos, cobertura parcial e completa, repetição de casos, suíte vazia,
sequência vazia, rejeição durante o percurso, ciclos e estados inalcançáveis.
Os testes são do verificador; não substituem o gerador do Gustavo.

## Organização das entregas

A implementação foi organizada em duas entregas locais na branch
`feat/verificador-lucas`, com a identidade Git de Lucas. A primeira contém a
verificação de casos e suítes, a migração compartilhada do tipo, os testes
básicos e o registro dessa decisão. A segunda acrescenta negativos, métricas,
os testes correspondentes e a documentação completa. Cada entrega é compilável.
Não houve push ao GitHub nessa organização.
