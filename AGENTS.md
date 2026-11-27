# Orientações para trabalhar neste repositório

O trabalho é dividido por integrante. Lucas é responsável por `src/Verifier.hs`;
respeite a divisão descrita em `docs/visao-geral.md` e o escopo do pedido atual.

Antes de alterar casos de teste, verificação ou cobertura, leia
[`docs/decisoes-verifier.md`](docs/decisoes-verifier.md). Esse registro explica
a mudança autorizada de `estadoEsperadoCaso` para `Maybe Estado`, as regras de
cobertura e a integração pendente com o gerador. Exemplos antigos com um
`Estado` diretamente no resultado esperado precisam ser migrados para `Just`.

Para validar o verificador, na raiz deste repositório:

```powershell
ghc -isrc -Wall -Werror -fno-code src/Types.hs src/FSM.hs src/Model.hs src/SUT.hs src/Verifier.hs
runghc -isrc tests/VerifierSpec.hs
```

Não atribua commits a colegas nem fabrique histórico para cumprir a avaliação.
Mantenha entregas e autoria reais; a organização dos commits deve ser combinada
com o usuário.
