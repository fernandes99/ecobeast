# 01. Evolução por horário

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [day-night](../day-night/) (o relógio do mundo e `day_phases`) e [progression](../progression/) (a oferta de Evolução)

## Contexto

O catálogo já tem o gatilho `time_of_day` (id 4, "Horário") e a coluna `evolutions.time_of_day` (`day` ou `night`, com CHECK no banco), mas o `evolutionOffer` de `server/src/domain/progression/evolution.ts` só olha o gatilho `level`. A linha do louva-a-deus precisa de duas regras do Mantorn, uma de dia e outra de noite.

## Escopo

- `server/src/domain/progression/evolution.ts` e o teste dele.
- `server/src/domain/world-clock/world-clock.ts` (`dayPartOf`) e o teste dele.
- `server/src/progression/progression.service.ts`: lê o `time_of_day` da regra e a hora ao planejar a vitória.
- `client/screens/codex/codex_detail.gd`: a seta da linha diz a hora, e o segundo ramo começa com "ou".
- `client/core/data/catalog_validator.gd`: confere as regras de horário.

## Requisitos

- **RF-01:** O "dia" é a Manhã (`morning`) e a Tarde (`afternoon`); o Final de tarde (`dusk`) e a Noite (`night`) são a noite. A parte do dia é a do relógio do mundo no momento em que a luta termina, a mesma para todos.
- **RF-02:** Uma regra `time_of_day` é oferecida ao subir de nível, com o nível novo ≥ `min_level` e a hora do RF-01 igual à `time_of_day` dela. Sem `min_level`, vale a partir do nível 1. A regra `level` não muda. Com mais de uma regra possível, vale a de menor id, como hoje.
- **RF-03:** A espécie oferecida fica guardada na escolha pendente, como hoje: aceitar mais tarde, com a hora já mudada, evolui para a mesma espécie. Quem cancela recebe a oferta de novo no próximo nível, com a hora daquele momento.
- **RF-04:** No Bestiário, a seta mostra "nv. 36" e, embaixo, "de dia" ou "à noite". Quando a forma seguinte da linha não evolui da anterior (outro ramo da mesma forma), aparece "ou" antes da seta.
- **RF-05:** O `CatalogValidator` do jogo recusa uma regra `time_of_day` sem `time_of_day`.

## Critérios de aceite

- [x] Testes de unidade do servidor passam, com os casos novos do `evolutionOffer` (de dia, à noite, abaixo do nível, duas regras) e do `dayPartOf`.
- [x] O lint e o typecheck do servidor passam.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [ ] Um Mantorn que passa do nível 36 de dia vira Solantis, e à noite vira Umbrantis.
- [ ] No Bestiário, a linha mostra Prayling › Mantorn › Solantis ou › Umbrantis, com a hora embaixo das setas.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] O `evolutionOffer` com o horário e os testes.
- [x] A hora no `progression.service.ts`.
- [x] O Bestiário e o `CatalogValidator`.
