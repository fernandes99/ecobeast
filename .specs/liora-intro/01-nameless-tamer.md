# 01. O Domador sem nome e Liora sem equipe

- **Status:** concluída
- **Depende de:** [home-island/01](../home-island/01-home-and-travel-data.md), [story/01](../story/01-story-marks.md)

## Contexto

A introdução começa antes do nome e acaba no inicial ([README](README.md#contexto)). O servidor precisa de um Domador para gravar os Marcos e montar o mapa, e hoje ele só existe com nome, e Explorar só abre com equipe. Esta fase muda as regras do servidor ([architecture](architecture.md#o-domador-sem-nome)); o jogo continua entrando como hoje até a [03](03-intro-steps.md).

## Escopo

- `POST /v1/me` sem nome e `PUT /v1/me/name`.
- Explorar a ilha casa sem equipe.
- O Marco `introducao_pulada` para as contas antigas.
- O `Session.set_tamer_name()` e o `Player.has_name()` no jogo.

## Fora do escopo

- A criação por cima do mapa e a entrada nova (fase 03).
- Renomear o Domador.

## Requisitos

- **RF-01:** `POST /v1/me` com o corpo vazio, `{}` ou sem `name` cria o Domador com `name = ""`, nível 1, 1000 moedas, o rosto padrão e sem equipe. Com `name`, valida e cria como hoje.
- **RF-02:** `PUT /v1/me/name` com `{ "name": "..." }` normaliza e valida como a criação (400 "Use de 2 a 16 letras, números ou espaços."). Sem Domador: 409 "Crie seu Domador primeiro.". Com nome: 409 "Seu Domador já tem nome.". Responde o jogador, como o `POST /v1/me`.
- **RF-03:** Dois `PUT /v1/me/name` ao mesmo tempo num Domador sem nome gravam só um: o `UPDATE` só pega a linha com `name = ''`, e quem não pegou responde o 409 do RF-02.
- **RF-04:** `POST /v1/exploration` com `island_id` da ilha casa abre para o Domador sem equipe. Sem equipe e com outra ilha ou sem `island_id`: 409 "Escolha seu primeiro Ecobeast antes de viajar.". Sem Domador: o 409 de hoje.
- **RF-05:** A ilha casa sem equipe sorteia os Ecobeasts das áreas como sempre (o nível das áreas não depende da equipe).
- **RF-06:** A migration `intro_skip` liga `introducao_pulada` em quem já tem Ecobeast ([architecture](architecture.md#as-contas-antigas)).
- **RF-07:** No jogo, `Player.has_name()` é `name != ""`, e `Session.set_tamer_name(name: String) -> Result` (o `set_name` é do `Node`) chama a rota e troca o `Session.player`. O `Session.create_player()` aceita o nome vazio e não manda o campo.
- **RF-08:** A documentação da API (`/docs`) descreve o `name` vazio, a rota nova e a regra da casa sem equipe.

## Critérios de aceite

- [x] `POST /v1/me` sem corpo cria um Domador com `name: ""`.
- [x] `PUT /v1/me/name` dá o nome uma vez e recusa a segunda.
- [x] Sem equipe, explorar a casa abre o mapa, e explorar outra ilha ou a zona responde o 409 do RF-04.
- [x] Depois da migration, todo jogador com Ecobeast tem `introducao_pulada`, e quem não tem, não.

## Desenho técnico

- `server/src/player/player.dto.ts`: `CreatePlayerBodyDto.name` opcional; `SetNameBodyDto`; as mensagens novas.
- `server/src/player/player.service.ts`: `create` com nome opcional; `setName`, com `updateMany({ where: { id, name: '' } })` e a contagem para o 409.
- `server/src/player/player.controller.ts`: `@Put('name')`.
- `server/src/exploration/exploration.service.ts`: o `teamAverage` nulo só passa quando a ilha pedida é a casa; a mensagem nova `NO_TEAM`.
- `server/prisma/migrations/<data>_intro_skip/migration.sql`.
- `client/domain/models/player.gd`, `client/core/autoload/session.gd` e os serviços (`ApiGameService`): `has_name`, `set_tamer_name`.
- Testes: e2e das duas rotas (`test/player.e2e-spec.ts`) e da exploração sem equipe (`test/home-island.e2e-spec.ts`, no grupo que roda depois, porque troca a ilha casa do banco).

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

## Tarefas

- [x] Criação sem nome e `PUT /v1/me/name`, com os testes.
- [x] A casa sem equipe, com os testes.
- [x] A migration `intro_skip`.
- [x] O `has_name` e o `set_tamer_name` no jogo.
