# 06. Observatório

- **Status:** concluída (falta o dono conferir numa ilha)
- **Depende de:** [01-key-buildings](01-key-buildings.md)

## Contexto

O dono mandou, em 2026-11-15, a arte de um observatório: uma torre redonda de pedra com cúpula de cobre e luneta, sobre uma base de grama, em 96×96. Esta fase o põe no catálogo como objeto de grade, com a arte dele em vez da do `make_town.gd`.

## Escopo

| id | slug | name | Formato | Variantes | Bloqueio |
| --- | --- | --- | --- | --- | --- |
| 41 | `observatory` | Observatório | três, o do Refúgio: (0, 0), (1, 0) e (1, −1) | 1 | os três bloqueiam |

O id 41 é o primeiro livre: os ids até 40 já foram usados, e os apagados não voltam.

## Fora do escopo

- Uma ação: o Observatório é só uma construção, sem tela. Uma ação pode vir depois, pelo editor.
- Desenhar a arte no `make_town.gd`: ela é a do dono, como veio.

## Requisitos

- **RF-01:** O catálogo ganha o tipo da tabela, por uma migração, e a carga inicial (`seed-data`) acompanha.
- **RF-02:** A arte fica em `res://assets/map_objects/observatory/1.png`, em 96×96, com o pé no ponto de apoio do formato, como os outros objetos. Com 3 hexágonos, a célula de um quadro tem 128 px, então a arte de 96 px é um quadro só. Em 1 hexágono, a célula teria 64 px, e o `MapObjectSprite` a partiria em 2 quadros.

## Critérios de aceite

- [x] O catálogo da API tem o `observatory` com os 3 hexágonos.
- [x] O `MapObjectSprite` mostra a arte inteira, num quadro, em cima dos 3 hexágonos.
- [ ] No editor (F2), a ferramenta Peças põe o Observatório, e no jogo o Domador não entra nos 3 hexágonos.

## Verificação

Em 2026-11-15:

- **A migração** está aplicada no banco, e o `GET /v1/catalog` devolve o tipo 41.
- **O teste da carga inicial** (`catalog-tables.spec.ts`) passa com o tipo novo.
- **Uma cena temporária** (apagada) desenhou o Observatório e o Refúgio sobre a grade: a arte é um quadro de 96 px, com o pé em (64, 58), no meio da frente dos 3 hexágonos, e a base de grama cabe neles.
- **O jogo sem janela** baixa o catálogo sem erro do `CatalogValidator` nem de script.
- **Não conferido:** o Observatório posto numa ilha pelo editor e o Domador em volta dele.
