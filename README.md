# Teste Baseado em Modelos em Haskell

Trabalho de Tópicos de Informática do Professor Felipe. A equipe é formada por
Pedro Vella, Victor Guerreiro, Bruno Zubiolo, Gustavo Abreu, Lucas Dos Santos e
Caio Greiffo.

O programa gera testes a partir da máquina de estados finita (FSM) de uma
máquina de vendas. O modelo tem quatro estados, seis eventos e seis transições
válidas. Cada caso começa em `Ociosa` e define uma sequência de eventos e o
resultado esperado, que pode ser um estado final ou a rejeição da sequência.

## Como executar

Na raiz do repositório, com GHC e Make disponíveis, compile e execute a
demonstração com `make run`. Os comandos abaixo também gravam uma cópia em
texto UTF-8 com os casos, as coberturas e os resultados comparativos.

```sh
make build
./mbt-haskell --relatorio relatorio.txt
```

No Windows, compile diretamente com GHC e execute pelo PowerShell.

```powershell
ghc -isrc -Wall src/Main.hs -o mbt-haskell.exe
.\mbt-haskell.exe --relatorio relatorio.txt
```

## O que aparece na demonstração

O programa valida a FSM e mostra o estado inicial, os estados, os eventos e as
transições. Depois, gera três suítes e executa cada uma no sistema sob teste
(SUT) correto e nas versões com defeitos de cancelamento e reposição de estoque.

| Suíte | Casos | Cobertura de estados | Cobertura de transições | SUT correto | Defeito de cancelamento | Defeito de estoque |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| All-States | 4 | 100% | 50% | 4/4 | 4/4 | 4/4 |
| All-Transitions | 6 | 100% | 100% | 6/6 | 5/6 | 5/6 |
| Testes negativos | 18 | 100% | 50% | 18/18 | 18/18 | 18/18 |

Os totais de cada SUT indicam quantos casos passaram. A cobertura mede os
estados e as transições percorridos pelas sequências no modelo, inclusive o
prefixo válido dos testes negativos. Os testes negativos exercitam eventos que
devem ser rejeitados no estado em que são enviados.

All-States chega a todos os estados pelos caminhos mínimos. All-Transitions
também exercita `Cancelar` e `ReporEstoque`. Por exemplo, a sequência
`InserirMoeda → Cancelar` deveria terminar em `Ociosa`, mas o SUT com defeito
de cancelamento fica em `ComCredito`. O relatório mostra essa diferença no
caso correspondente.

Consulte a [visão geral do projeto](docs/visao-geral.md) para entender o fluxo
de geração e verificação dos testes.

