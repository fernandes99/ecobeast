# 01. A descrição dos estados

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [field-effects](../field-effects/) (os estados 10 e 11)

## Escopo

A coluna `status_conditions.description` (`TEXT NOT NULL`), com estes textos, tirados das regras do servidor de hoje:

| id | Estado | Descrição |
| --- | --- | --- |
| 1 | Queimado | Perde 1/16 do HP máximo no fim de cada vez, e as Técnicas físicas dele causam metade do dano. A chance de captura fica 1,5 vez maior. |
| 2 | Envenenado | Perde 1/8 do HP máximo no fim de cada vez. A chance de captura fica 1,5 vez maior. |
| 3 | Paralisado | A Velocidade cai pela metade, e em cada vez há 25% de chance de não agir. A chance de captura fica 1,5 vez maior. |
| 4 | Adormecido | Não age por 1 a 3 vezes, sorteadas ao adormecer e de novo ao voltar ao campo, e depois acorda. A chance de captura fica 2,5 vezes maior. |
| 5 | Congelado | Não age, e em cada vez há 20% de chance de descongelar e agir. A chance de captura fica 2,5 vezes maior. |
| 6 | Confuso | Por 2 a 5 vezes, há 33% de chance de se golpear em vez de agir, com um golpe físico de Poder 40. |
| 7 | Amedrontado | Perde a próxima vez. |
| 8 | Preso | Por 2 vezes, não anda nem pode ser trocado, e o time dele não pode fugir. |
| 9 | Atordoado | Não anda na próxima vez, mas ainda pode agir. |
| 10 | Encharcado | Por 3 vezes, recebe 1,5 vez o dano das Técnicas de Volt e metade do das de Fogo. |
| 11 | Brotando | Recupera 1/16 do HP máximo no fim de cada vez, por 5 vezes. |

## Requisitos

- **RF-01:** A migração `20270113000000_status_descriptions` cria a coluna e grava os 11 textos; o `seed-data/status_conditions.json` ganha a coluna nas linhas 1 a 9 (as 10 e 11 vieram por migração).
- **RF-02:** O `catalog_schema.gd` confere a coluna como texto não vazio.
- **RF-03:** No F1, a aba Estados mostra a descrição embaixo do nome do estado, quebrando a linha.
- **RF-04:** Quem mudar a regra de um estado no servidor atualiza a descrição dele na mesma entrega.

## Critérios de aceite

- [ ] No F1, cada estado mostra a descrição.
- [x] `godot --headless --path client --editor --quit` carrega o catálogo sem erro, e os testes do servidor passam.
