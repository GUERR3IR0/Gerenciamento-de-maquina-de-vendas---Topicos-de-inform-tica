# Orientações para trabalhar neste repositório

O trabalho é dividido por integrante. Lucas é responsável por `src/Verifier.hs`;
respeite a divisão descrita em `docs/visao-geral.md` e o escopo do pedido atual.

Antes de alterar casos ou verificação, leia
[`docs/decisoes-verifier.md`](docs/decisoes-verifier.md). O registro explica a
mudança autorizada de `estadoEsperadoCaso` para `Maybe Estado` e a migração dos
consumidores. Casos válidos usam `Just estado`; rejeições esperadas usam `Nothing`.

Para validar o verificador, na raiz deste repositório:

```powershell
ghc -isrc -Wall -Werror -fno-code src/Types.hs src/FSM.hs src/Model.hs src/SUT.hs src/Verifier.hs
runghc -isrc tests/VerifierSpec.hs
```

Mantenha entregas e autoria reais; a organização dos commits deve ser combinada
com o usuário. A segunda entrega acrescentará os negativos e as métricas.
