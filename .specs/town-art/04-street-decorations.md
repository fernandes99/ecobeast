# 04. Decorações de rua

- **Status:** concluída
- **Depende de:** [03-village-objects](03-village-objects.md)

## Contexto

As cidades das referências do dono têm postes de luz, placas, canteiros de flores e bancos pelas ruas, e a ilha não tem nenhum deles. Esta fase cria os quatro como tipos de objeto, no estilo do guia.

## Escopo

| id | slug | name | Formato | Variantes (_a revisar_) | Bloqueio padrão |
| --- | --- | --- | --- | --- | --- |
| 36 | `lamp_post` | Poste de luz | um | 2: de ferro e de madeira | bloqueia |
| 37 | `sign` | Placa | um | 2: de madeira e de pedra | bloqueia |
| 38 | `flower_bed` | Canteiro de flores | um | 3: vermelho e amarelo, rosa e branco, e misturado | não bloqueia |
| 39 | `bench` | Banco | um | 2: de madeira e de pedra | bloqueia |

## Fora do escopo

- Poste aceso que muda com a hora, porque o jogo não tem dia e noite.
- Texto na placa.
- Mais de um objeto por hexágono: cada decoração ocupa o hexágono dela, como os outros objetos.

## Requisitos

- **RF-01:** O catálogo ganha os quatro tipos da tabela, por uma migração.
- **RF-02:** O `make_town.gd` desenha os quatro, seguindo o guia. O poste tem de 36 a 44 px de altura (bem mais alto que o Domador), a lâmpada usa a cor de luz do guia e não é animada.
- **RF-03:** O canteiro não bloqueia, e o Domador anda por cima dele. Ele é desenhado baixo, até 16 px de altura, só na metade da frente do hexágono, abaixo do pé do Domador: um objeto é desenhado depois dos atores da linha dele, e o canteiro cobriria o Domador se subisse acima do pé.
- **RF-04:** A arte fica centrada no hexágono e ocupa só o meio dele. Um poste ou uma placa não passa de 24 px de largura, e um banco de 40 px.

## Critérios de aceite

- [x] O gerador grava as variantes dos quatro tipos.
- [ ] O catálogo traz os quatro tipos, e o editor os põe (com o dono, no F2).
- [x] Numa imagem do mapa, o Domador de pé num canteiro aparece inteiro, atrás das flores, e os postes ficam mais altos que ele.

## Desenho técnico

- Servidor: a migração `server/prisma/migrations/20261118000000_street_decorations/migration.sql`, no formato da [01](01-key-buildings.md), com a carga inicial e o teste da carga (34 objetos).
- `make_town.gd`: os quatro tipos no `TYPES` e as funções de desenho.
- `.specs/island-villages/architecture.md`: a tabela de tipos e a de tamanhos.

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_town.gd -- lamp_post sign flower_bed bench
cd server && npx prisma migrate deploy && npm run test:e2e
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

Uma cena temporária com as decorações em volta de uma praça e o Domador num canteiro.

Feita em 2026-11-12:
- **Arte:** o `make_town.gd` gravou os postes (64×55 e 64×60, com 38 a 40 px de altura), as placas (64×41, com setas, sem texto), os canteiros (64×26, 14 px de altura) e os bancos (64×30 e 64×37).
- **Mapa:** numa praça de teste (cena temporária, já apagada), com o Refúgio, a Loja, um santuário, postes nos cantos, placas nas entradas, bancos e canteiros, o Domador de pé num canteiro aparece inteiro, e os postes ficam mais altos que ele.
- **Servidor:** a migração foi aplicada, a carga inicial ganhou os 4 tipos (o canteiro com `blocks` falso) e o teste da carga conta 34 objetos. `lint`, `typecheck`, `npm test` e `npm run test:e2e` passam.
- **Projeto:** abre sem erro de script.
- **Falta o dono:** pôr as decorações no F2.

## Tarefas

- [x] A migração e a tabela do `architecture.md` da island-villages.
- [x] A arte dos quatro tipos.
- [x] Conferir numa imagem e no editor, e atualizar o `client/CLAUDE.md`.
