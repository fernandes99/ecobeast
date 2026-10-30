# 05. Jogador pelo servidor

- **Status:** concluída
- **Depende de:** [03-player-api](03-player-api.md), [04-client-login](04-client-login.md)

## Contexto

O jogo já entra com a conta Google ([04](04-client-login.md)), e o servidor já tem as rotas do jogador ([03](03-player-api.md)). Mas o progresso continua sendo criado e salvo no aparelho, pelo `LocalGameService`. Esta fase troca o serviço por um que chama as rotas: o `Session` e as telas continuam iguais, e saem do cliente o save local e as regras de geração do inicial. Daqui em diante, o progresso só existe no banco.

## Escopo

- `ApiGameService` no lugar do `LocalGameService`.
- Remoção do save local e das regras do cliente.
- Documentos que descrevem o jogador local.

## Fora do escopo

- Rotas ou regras novas no servidor.
- Telas novas.

## Requisitos

- **RF-01:** `res://core/services/api_game_service.gd` (`class_name ApiGameService`, estende `GameService`), pelas rotas de [architecture.md](architecture.md#rotas-do-jogador), com `Api.request(..., authenticated = true)`:
  - `get_player()` → `GET /v1/me`; `data` = `Player.from_dict(player)` ou `null`;
  - `create_player(raw_name)` → `POST /v1/me` com `{"name": raw_name}`;
  - `choose_starter(species_id)` → `POST /v1/me/starter`;
  - `reset_progress()` → `DELETE /v1/me`.
  
  Erro: `Result.failure` com o `error` do `ApiResponse` (a mensagem do servidor, em pt-BR, ou a de rede).
- **RF-02:** O `Session` cria o `ApiGameService` (sem repositório). O `@warning_ignore("redundant_await")` continua, porque os métodos do `GameService` são `@abstract`.
- **RF-03:** A tela do nome continua conferindo o nome no próprio aparelho (`Player.normalize_name` e `Player.is_valid_name`) para habilitar o botão na hora; quem decide é o servidor.
- **RF-04:** `Player.from_dict` e `CreatureInstance.from_dict` leem `stats` do JSON do servidor (já leem); nenhuma tela calcula stats.
- **RF-05:** Saem do cliente, com os `.uid`: `res://core/services/local_game_service.gd`, `local_player_repository.gd`, `player_repository.gd`, `res://domain/rules/` (`creature_factory.gd`, `stat_calculator.gd`, `xp_curve.gd`) e `res://core/util/uuid.gd` (a pasta `util/` some se ficar vazia). O que ainda for usado por outro arquivo fica e é citado nas decisões da implementação.
- **RF-06:** Na abertura, se existir `user://save.json` (ou `save.tmp.json`, `save.corrupted.json`), o boot apaga o arquivo; o progresso antigo é descartado.
- **RF-07:** "Apagar progresso" (debug) passa a apagar o Domador no servidor e leva para a tela do nome (`title`), com a sessão mantida.
- **RF-08:** Documentos:
  - `.specs/onboarding/architecture.md` ("Peças", contrato e regras): o serviço é o `ApiGameService`, as regras moram no servidor ([02](02-player-rules.md)), e o save local saiu;
  - `.specs/foundation/architecture.md` (árvore do cliente, camadas);
  - `.specs/game-data/architecture.md`, se citar o save local;
  - `client/CLAUDE.md` e o `CLAUDE.md` da raiz ("o jogador e as regras ainda rodam no cliente" deixa de valer);
  - `.specs/roadmap.md`: `auth-google` como `concluída`.

## Critérios de aceite

- [ ] Passo do dono, com uma conta Google nova: login → nome → escolha do inicial → Hub com o inicial; fechar e abrir o jogo leva direto ao Hub com o mesmo inicial.
- [ ] Passo do dono: a mesma conta em outro aparelho (ou depois de apagar `user://session.json` e entrar de novo) encontra o mesmo Domador e a mesma equipe.
- [x] No banco, `players`, `creature_instances`, `creature_instance_stats` e `creature_instance_skills` têm as linhas do Domador criado. (Conferido por consulta do servidor de teste, não pelo painel.)
- [x] Um nome repetido (segundo `POST`) e um inicial escolhido duas vezes mostram as mensagens do servidor nas telas.
- [x] "Apagar progresso" (debug) leva à tela do nome sem pedir login, e o banco não tem mais o Domador.
- [x] Um `user://save.json` antigo é apagado na abertura.
- [x] `grep` no cliente não encontra `LocalGameService`, `LocalPlayerRepository`, `CreatureFactory`, `StatCalculator`, `XpCurve` nem `save.json` fora do RF-06.
- [x] O jogo roda sem erros de script e sem avisos (conferido com `-d`, que mostra os avisos fora do editor).

## Desenho técnico

**Criar**

- `res://core/services/api_game_service.gd`.

**Alterar**

- `res://core/autoload/session.gd` (RF-02), `res://screens/main/main.gd` (RF-06), `res://screens/hub/profile_debug_panel.gd` (RF-07), `res://core/services/game_service.gd` (comentário: "Hoje: ApiGameService").
- Os documentos do RF-08.

**Remover**

- Os arquivos do RF-05.

## Verificação

Com o servidor rodando:

```bash
godot --headless --path client --quit-after 30
```

Para conferir o fluxo sem o Google, um script temporário (fora do repositório) sobe o servidor com o `TokenVerifier` trocado por um que aceita tokens assinados por uma chave gerada na hora, e uma cena temporária do jogo usa um desses tokens para criar o Domador, escolher o inicial, ler de novo e apagar. Os dois são apagados no fim. O login de verdade, nos dois aparelhos, é passo do dono.

## Tarefas

- [x] `ApiGameService` e `Session` (RF-01, RF-02).
- [x] Remover o save local e as regras (RF-05, RF-06); "Apagar progresso" (RF-07); conferir `grep` e avisos.
- [x] Conferência com o servidor de teste e a cena temporária; apagar os dois.
- [x] Documentos (RF-08); marcar esta spec, a tabela do README e o roadmap como `concluída`; commit `feat: jogador pelo servidor`.

## Decisões da implementação

- **`to_dict` saiu dos modelos**, com `DictFields.id_or_null`: só o save local os usava. O RF-05 não os listava, mas ficariam sem uso.
- **`profile_debug_panel.gd` não mudou:** ele já chamava `Session.reset_progress()` e ia para `title`; trocar o serviço bastou para o RF-07.
- **Resposta `200` sem o campo `player`** vira `Result.failure` com a mensagem de erro do servidor, em vez de parecer uma conta sem Domador e abrir a tela do nome.
- **Mensagens do `GameService`:** "Não foi possível carregar seu progresso." e "Não foi possível apagar o progresso." eram do save local. Agora vale a mensagem do `ApiResponse`.
- **Conferência:** 34 verificações numa cena temporária, contra a API real na porta 3198 com o `TokenVerifier` de `test/support/tokens.ts` e o banco de verdade, sem Google. Cobriu boot com os três arquivos antigos, nome, escolha, as mensagens do servidor nas telas, reabertura, falta de rede, "Apagar progresso" e as linhas do banco em cada passo; o servidor apagou o Domador de teste no fim. A cena rodou com um `client/override.cfg` temporário (pasta `user://` e `ecobeast/api/base_url` próprias), para não tocar na sessão nem no save do dono. Tudo foi apagado.
- **Token real:** uma segunda cena temporária usou a sessão do dono no servidor de desenvolvimento: `GET /v1/me` deu `200` com o token do Supabase, e, com o vencimento forçado, a renovação trocou o token, regravou `session.json` e o `GET` seguinte deu `200`.
