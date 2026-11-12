# 04. Decorações de rua

- **Status:** rascunho
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
- **RF-03:** O canteiro não bloqueia, e o Domador anda por cima dele. Ele é desenhado baixo, até 16 px de altura, para não cobrir o Domador.
- **RF-04:** A arte fica centrada no hexágono e ocupa só o meio dele. Um poste ou uma placa não passa de 24 px de largura, e um banco de 40 px.

## Critérios de aceite

- [ ] O gerador grava as variantes dos quatro tipos.
- [ ] O catálogo traz os quatro tipos, e o editor os põe (com o dono, no F2).
- [ ] Numa imagem do mapa, o Domador de pé num canteiro aparece por cima das flores, e os postes ficam mais altos que ele.

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

## Tarefas

- [ ] A migração e a tabela do `architecture.md` da island-villages.
- [ ] A arte dos quatro tipos.
- [ ] Conferir numa imagem e no editor, e atualizar o `client/CLAUDE.md`.
