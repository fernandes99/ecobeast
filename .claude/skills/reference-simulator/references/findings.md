# O que já foi decifrado

Cada achado diz se foi **confirmado**, quando o código mostra a regra sem dúvida, ou **deduzido**, quando depende de interpretar um endereço. Endereços são do `PokeGame.exe` da versão 4.5, com base `0x400000`. Ao decifrar algo novo, acrescente aqui com a data.

## Endereços

| Endereço | O que é | Como se sabe |
| --- | --- | --- |
| `0x4030F8` | `Random(N)` do Delphi: recebe N em `eax` e devolve de 0 a N-1 em `eax` | Confirmado: `imul edx, [RandSeed], 0x08088405`, o gerador do Delphi |
| `0x4A8C78` | Dinheiro do jogador (inteiro de 32 bits) | Confirmado: a vitória soma nele, a derrota corta pela metade |
| `0x4A8C75` | Número de insígnias (byte) | Confirmado: soma 1 logo antes de "You earned the …" |
| `0x492BD1` | Marca do fim do jogo, provavelmente ter vencido a Liga (byte) | Deduzido |
| `0x404DDC` | Junta textos; `edx` diz quantos | Deduzido pelo uso |
| `0x4090B8` | Inteiro para texto | Deduzido pelo uso |
| `0x41037C`, `0x414434`, `0x41462C`, `0x4167DC`, `0x4167F4`, `0x416800`, `0x411720` | Número grande (sem limite de 32 bits): copia, cria de inteiro, cria de real, soma, multiplica, compara e converte para inteiro | Deduzido pelo uso |
| `[[0x48F470]+0x2F8]+0x220`, método `+0x38` | Escreve uma linha no log da luta | Deduzido: sempre logo depois de montar uma mensagem |

## Fim da luta vencida (`0x488700` a `0x488C00`)

Mensagens em ordem: "Enemy X fainted!", "X gained N experience points!", "X grew to level N" e "You got N!". É a única rotina que soma dinheiro, e ela não separa selvagem de treinador.

**Dinheiro (confirmado, 2026-11-03):**

1. `x = Random(3) + 1`, ou seja, 1, 2 ou 3.
2. Se `x = 3`, vira 4. Ficam 1, 2 ou 4, com a mesma chance.
3. `prêmio = x × 250`, ou seja, 250, 500 ou 1000.
4. Com 4 a 7 insígnias, ×2. Com 8 a 11, ×4. Com 12 ou mais e sem a marca do fim do jogo, ×6.
5. Com a marca do fim do jogo, ×8 sobre o valor do passo 3.
6. `dinheiro += prêmio`.

O nível do inimigo não entra na conta.

## Derrota (`0x4896D0` a `0x489795`)

**Dinheiro (confirmado, 2026-11-03):** mostra "You lost N!" com metade do dinheiro e faz `dinheiro = dinheiro >> 1`, ou seja, perde a metade, arredondada para baixo.

## Insígnia (`0x486C5C` a `0x486D00`)

Soma 1 em `0x4A8C75` e mostra "You earned the …". Não mexe no dinheiro.

## Textos achados e ainda não decifrados

- "Tournament Prizes", "Initializing tournament prizes", "You won the tournament! Now for the unveiling of your prize..." e "You won a L." (prêmio do torneio, provavelmente um Pokémon de certo nível).
- "Money (Pays out 10:1": aposta.
- "You don't have enough money!": loja, seis vezes.
