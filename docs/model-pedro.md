# Guia de estudo do `src/Model.hs`

**Responsável:** Pedro Vella
**Arquivo:** `src/Model.hs` (só esse arquivo é meu)
**Branch:** `feat/modelo-pedro`

> Os arquivos `Types.hs` e `FSM.hs` são do **Victor**. Mesmo assim, na arguição
> qualquer integrante pode ser perguntado sobre qualquer parte, então no fim
> deste documento tem um resumo de como o meu arquivo se liga com os outros.

---

## 1. O que o meu arquivo faz, em uma frase

O `Model.hs` **descreve a Máquina de Vendas** (o modelo) e oferece **duas formas
de mostrar esse modelo**: como texto no terminal e como grafo para os slides.

No Teste Baseado em Modelos (MBT), o **modelo** é a peça central. Ele diz como o
sistema *deveria* se comportar. A partir dele:

- o **gerador** (Gustavo) cria os casos de teste automaticamente;
- o **verificador** (Lucas) confere se o sistema real (SUT, do Bruno) fez o que o
  modelo previa.

Ou seja: **sem o meu modelo, ninguém tem o que testar.**

---

## 2. Os commits

| Commit | Mensagem | O que entrou |
|---|---|---|
| `2b94432` | `feat(model): modelagem da Maquina de Vendas (maquinaVendasFSM)` | A definição do modelo: estados, eventos e transições. |
| `2906d57` | `feat(model): visualizacao do modelo (formatarTabelaModelo e exportarDot)` | As duas funções que mostram o modelo como texto. |

---

## 3. Conceitos que preciso saber antes de explicar

### O que é uma FSM (Máquina de Estados Finita)?
É um jeito de descrever um sistema com:
- **Estados:** as "situações" em que o sistema pode estar (ex.: `Ociosa`);
- **Eventos:** as "ações" que acontecem (ex.: `InserirMoeda`);
- **Transições:** regras do tipo *"se estou no estado X e acontece o evento Y,
  vou para o estado Z"*;
- **Estado inicial:** onde o sistema começa.

É **finita** porque tem um número limitado de estados (aqui, 4).
É **determinística** porque, para cada estado e evento, existe **no máximo um**
destino. Nunca há duas opções.

### Os tipos que eu uso (vêm do `Types.hs`, do Victor)

```haskell
data Estado = Ociosa | ComCredito | Dispensando | SemEstoque

data Evento = InserirMoeda | Cancelar | SelecionarProduto
            | ConfirmarEntrega | EntregaUltimoItem | ReporEstoque

data Transicao = Transicao
    { origemTransicao  :: Estado
    , eventoTransicao  :: Evento
    , destinoTransicao :: Estado
    }

data FSM = FSM
    { estadosFSM       :: [Estado]
    , eventosFSM       :: [Evento]
    , transicoesFSM    :: [Transicao]
    , estadoInicialFSM :: Estado
    }
```

- `Estado` e `Evento` são **tipos algébricos**: listam todos os valores possíveis.
  Isso é bom porque o compilador **não deixa** eu escrever um estado que não existe.
- `Transicao` guarda três coisas: **origem**, **evento** e **destino**.
- `FSM` junta tudo: a lista de estados, a lista de eventos, a lista de transições
  e o estado inicial.
- Os nomes entre chaves (`origemTransicao`, `estadosFSM`...) são **campos**. Em
  Haskell, cada campo também vira uma função que "pega" aquele valor. Exemplo:
  `origemTransicao t` devolve a origem da transição `t`.

---

## 4. Commit 1: o modelo (`maquinaVendasFSM`)

```haskell
maquinaVendasFSM :: FSM
maquinaVendasFSM = FSM
    { estadosFSM =
        [ Ociosa
        , ComCredito
        , Dispensando
        , SemEstoque
        ]
    , eventosFSM =
        [ InserirMoeda
        , Cancelar
        , SelecionarProduto
        , ConfirmarEntrega
        , EntregaUltimoItem
        , ReporEstoque
        ]
    , transicoesFSM =
        [ Transicao Ociosa      InserirMoeda      ComCredito
        , Transicao ComCredito  Cancelar          Ociosa
        , Transicao ComCredito  SelecionarProduto Dispensando
        , Transicao Dispensando ConfirmarEntrega  Ociosa
        , Transicao Dispensando EntregaUltimoItem SemEstoque
        , Transicao SemEstoque  ReporEstoque      Ociosa
        ]
    , estadoInicialFSM = Ociosa
    }
```

### Explicando linha a linha
- `maquinaVendasFSM :: FSM` é a **assinatura**: "isto é um valor do tipo FSM".
  Não é uma função, porque não recebe nada. É só um valor fixo, uma constante.
- `FSM { ... }` monta a máquina preenchendo cada campo.
- `estadosFSM = [...]` tem os **4 estados**.
- `eventosFSM = [...]` tem os **6 eventos**.
- `transicoesFSM = [...]` tem as **6 transições**. Cada linha se lê como
  **"de onde, com qual evento, para onde"**.
- `estadoInicialFSM = Ociosa`: a máquina começa parada, esperando cliente.

### O significado de cada transição

| De | Evento | Para | Na vida real |
|---|---|---|---|
| Ociosa | InserirMoeda | ComCredito | O cliente pôs dinheiro. |
| ComCredito | Cancelar | Ociosa | Desistiu, e a máquina devolve a moeda. |
| ComCredito | SelecionarProduto | Dispensando | Escolheu o produto, e a máquina começa a entregar. |
| Dispensando | ConfirmarEntrega | Ociosa | Entregou, e ainda tem estoque. |
| Dispensando | EntregaUltimoItem | SemEstoque | Entregou a última unidade. |
| SemEstoque | ReporEstoque | Ociosa | Alguém reabasteceu a máquina. |

### Desenho do modelo

```
            InserirMoeda
   Ociosa ───────────────▶ ComCredito
     ▲  ▲  ◀───────────────    │
     │  │      Cancelar        │ SelecionarProduto
     │  │                      ▼
     │  └──────────────── Dispensando
     │   ConfirmarEntrega      │
     │                         │ EntregaUltimoItem
     │                         ▼
     └──────────────────── SemEstoque
          ReporEstoque
```

### E se acontecer um evento que não está na tabela?
Por exemplo, `Cancelar` estando em `Ociosa`. Não existe transição para isso,
então o evento é **inválido** naquele estado. A função `executarTransicao` do
Victor devolve `Nothing` nesse caso. Esses eventos inválidos são usados pelo
Lucas nos **testes negativos**.

---

## 5. Commit 2: as funções de visualização

### 5.1 `formatarTabelaModelo`

```haskell
formatarTabelaModelo :: FSM -> String
formatarTabelaModelo fsm = unlines (map formatarLinha (transicoesFSM fsm))
  where
    formatarLinha t =
        show (origemTransicao t)
        ++ " --" ++ show (eventoTransicao t) ++ "--> "
        ++ show (destinoTransicao t)
```

**Assinatura:** `FSM -> String` quer dizer "recebe uma FSM e devolve um texto".

**Como funciona, de dentro para fora:**
1. `transicoesFSM fsm` pega a **lista de transições** da máquina.
2. `map formatarLinha (...)` aplica `formatarLinha` em **cada** transição. O
   resultado é uma lista de textos, um por transição.
3. `unlines (...)` junta essa lista em **um único texto**, colocando uma quebra
   de linha (`\n`) depois de cada item.

**A função auxiliar `formatarLinha`** (definida no `where`, que é onde se
declaram funções auxiliares locais):
- `show` transforma um valor em texto. Exemplo: `show Ociosa` dá `"Ociosa"`.
  Funciona porque os tipos têm `deriving (Show)` no `Types.hs`.
- `++` **concatena** (junta) textos.
- O resultado tem o formato `Origem --Evento--> Destino`.

**Saída no terminal:**
```
Ociosa --InserirMoeda--> ComCredito
ComCredito --Cancelar--> Ociosa
ComCredito --SelecionarProduto--> Dispensando
Dispensando --ConfirmarEntrega--> Ociosa
Dispensando --EntregaUltimoItem--> SemEstoque
SemEstoque --ReporEstoque--> Ociosa
```

### 5.2 `exportarDot`

```haskell
exportarDot :: FSM -> String
exportarDot fsm = unlines (["digraph MaquinaDeVendas {"] ++ map formatarSeta (transicoesFSM fsm) ++ ["}"])
  where
    formatarSeta t =
        "  " ++ show (origemTransicao t)
        ++ " -> " ++ show (destinoTransicao t)
        ++ " [label=\"" ++ show (eventoTransicao t) ++ "\"];"
```

**Para que serve:** gera o modelo no formato **DOT**, que é a linguagem do
programa **Graphviz**. O Graphviz lê esse texto e **desenha o grafo** sozinho,
e essa imagem vai nos slides.

**Como funciona:** a ideia é a mesma da função anterior.
1. A primeira linha é `"digraph MaquinaDeVendas {"`. `digraph` quer dizer
   *grafo direcionado*, ou seja, as setas têm sentido.
2. Depois vem uma linha `A -> B [label="Evento"];` para **cada transição**
   (`map formatarSeta`).
3. A última linha é `"}"`, que fecha o grafo.
4. O `++` aqui junta **listas**: lista de cima + lista do meio + lista de baixo.
   Depois o `unlines` transforma tudo num texto só.
5. O `\"` é uma **aspa dentro do texto**. A barra avisa ao Haskell que essa aspa
   faz parte do texto e não marca o fim dele.

**Saída:**
```
digraph MaquinaDeVendas {
  Ociosa -> ComCredito [label="InserirMoeda"];
  ComCredito -> Ociosa [label="Cancelar"];
  ComCredito -> Dispensando [label="SelecionarProduto"];
  Dispensando -> Ociosa [label="ConfirmarEntrega"];
  Dispensando -> SemEstoque [label="EntregaUltimoItem"];
  SemEstoque -> Ociosa [label="ReporEstoque"];
}
```

**Para virar imagem:** salve a saída num arquivo `modelo.dot` e rode
`dot -Tpng modelo.dot -o modelo.png`.

### Por que as duas funções recebem uma `FSM` em vez de usar direto a `maquinaVendasFSM`?
Porque assim elas funcionam para **qualquer** máquina de estados, não só a de
vendas. Isso deixa o código reutilizável, e é isso que o guia pede no contrato:
`formatarTabelaModelo :: FSM -> String`.

---

## 6. Como o meu arquivo se liga com o resto do projeto

```
Types.hs (Victor)   define os tipos: Estado, Evento, Transicao, FSM
      │
      ▼
Model.hs (EU)       cria a máquina concreta: maquinaVendasFSM
      │
      ├──▶ FSM.hs (Victor)       executa sequências e valida o modelo
      ├──▶ Generator.hs (Gustavo) gera os casos de teste a partir do modelo
      ├──▶ Verifier.hs (Lucas)    compara o SUT com o que o modelo prevê
      └──▶ Main.hs (Caio)         imprime a tabela e o DOT na demonstração
```

- **`import Types`** no topo do meu arquivo é o que me dá acesso aos tipos.
- A lista no topo (`module Model ( maquinaVendasFSM, formatarTabelaModelo,
  exportarDot ) where`) diz **o que eu exporto**, ou seja, o que os outros
  arquivos podem usar.

### Funções do Victor (`FSM.hs`) que usam o meu modelo
- `executarTransicao fsm estado evento` procura a transição que bate com o
  estado e o evento. Se acha, devolve `Just destino`. Se não acha, devolve
  `Nothing`.
- `executarSequencia fsm eventos` aplica uma lista de eventos a partir do
  estado inicial e diz em que estado terminou.
- `estadosAlcancaveis fsm` faz uma **BFS** (busca em largura) para descobrir
  quais estados dá para alcançar a partir do inicial. No nosso modelo são os 4.
- `validarFSM fsm` confere se o modelo está coerente: o estado inicial existe,
  as transições usam estados e eventos que existem e não há transição duplicada.
  **O meu modelo passa nessa validação.**

---

## 7. Cobertura, a parte mais importante da demonstração

- **All-States (todos os estados):** os testes precisam **visitar todos os
  estados** pelo menos uma vez.
- **All-Transitions (todas as transições):** os testes precisam **passar por
  todas as transições** pelo menos uma vez. É mais forte que o All-States.

**Exemplo com o meu modelo:**
A sequência `[InserirMoeda, SelecionarProduto, EntregaUltimoItem]` passa por
`Ociosa → ComCredito → Dispensando → SemEstoque`.
- Visita os **4 de 4 estados**, então tem **100% de All-States**.
- Usa só **3 de 6 transições**, então tem **50% de All-Transitions**.

**Por que isso importa:** o Bruno cria um SUT **com defeito** no `Cancelar`
(ele não volta para `Ociosa`). Os testes de All-States **nunca usam o
`Cancelar`**, então **o defeito passa sem ser visto**. Os testes de
All-Transitions são obrigados a usar a transição `ComCredito --Cancelar-->
Ociosa`, então **pegam o defeito**.

---

## 8. Perguntas prováveis na arguição e como responder

**Qual foi a sua parte?**
O `Model.hs`: a definição da Máquina de Vendas como FSM e as funções que mostram
o modelo como tabela no terminal e como grafo DOT para os slides.

**Por que esse modelo é uma FSM determinística?**
Porque, para cada par (estado, evento), existe no máximo uma transição. Nunca há
dúvida sobre o próximo estado.

**Quantos estados, eventos e transições? Qual o estado inicial?**
4 estados, 6 eventos, 6 transições. O inicial é `Ociosa`.

**O que acontece se eu mandar `Cancelar` estando em `Ociosa`?**
Não existe essa transição no modelo, então o evento é inválido ali.
`executarTransicao` devolve `Nothing`. Isso vira teste negativo.

**Por que usar tipos algébricos em vez de strings para os estados?**
Porque o compilador garante que só existem aqueles valores. Se eu errar o nome
de um estado, o código nem compila. Com string, o erro só apareceria na hora de
rodar.

**O que `map`, `show`, `++` e `unlines` fazem?**
- `map f lista` aplica `f` em cada elemento da lista.
- `show x` transforma `x` em texto.
- `++` junta dois textos ou duas listas.
- `unlines lista` junta uma lista de textos num texto só, com uma quebra de linha
  entre eles.

**O que é o `where`?**
É onde se definem funções auxiliares que só existem dentro daquela função, como
o `formatarLinha` e o `formatarSeta`.

**Para que serve o DOT?**
É o formato do Graphviz. Ele lê o texto e desenha o grafo automaticamente. A
gente usa essa imagem nos slides.

**Qual o papel do modelo no MBT?**
Ele é a especificação de como o sistema deve se comportar. Os testes são
gerados a partir dele, e o resultado esperado de cada teste também vem dele.

**Quais as limitações do MBT?**
- **Explosão de estados:** sistemas grandes têm estados demais para modelar.
- **Custo de manutenção:** quando o sistema muda, o modelo precisa mudar junto.
- **Depende da fidelidade do modelo:** se o modelo estiver errado, os testes
  também ficam errados.
