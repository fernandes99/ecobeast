# 03. Conteúdo das linhas iniciais

- **Status:** concluída
- **Depende de:** [02-core-tables](02-core-tables.md)

## Contexto

Com as tabelas de referência preenchidas, falta o conteúdo que a escolha do inicial e o Hub mostram. Esta fase cria as 3 linhas evolutivas iniciais completas — Fogo, Água e Flora, com duas Ascensões cada —, os traços, as técnicas que os learnsets usam e as opções da escolha do inicial.

A linha de Fogo vem do `GDD.md` (seções "Técnicas por nível" e "Evoluções"). As linhas de Água e Flora foram propostas no planejamento seguindo o mesmo padrão e estão **_a revisar_** pelo dono: nomes, conceito, números e técnicas podem mudar sem cerimônia.

Conceito das linhas:

- **Fogo — Fagulho → Brasalobo → Infernolobo:** lobo de brasas, rápido e ofensivo; a forma final ganha Sombra.
- **Água — Gotículo → Marisgarra → Abissarra** _(a revisar)_: crustáceo de poça de maré, defensivo; o casco vira metal na forma final (Água/Metal).
- **Flora — Brotelho → Ramalebre → Zefirama** _(a revisar)_: lebre com broto entre as orelhas, de ataque especial; a forma final ganha Vento.

O triângulo funciona pela tabela do GDD: Fogo vence Flora, Água vence Fogo e Flora vence Água.

## Escopo

Preencher: `species`, `species_elements`, `species_stats`, `traits`, `species_traits`, `skills`, `skill_effects`, `species_skills`, `evolutions`, `starter_options`.

## Fora do escopo

- Técnicas ensináveis (`teachable`) — nenhuma no MVP.
- Arte, sons e textos além da descrição do Bestiário.
- Implementação dos efeitos dos traços e técnicas (iniciativa `battle-core`).

## Requisitos

**Espécies**

- **RF-01:** `species.json` com as 9 espécies abaixo. Todas com `growth_rate_id` = Médio, `rarity_id` = Raro, `capture_rate` = 45 e `gender_ratio` = 0.5. `evolves_from_species_id` aponta para a forma anterior da linha (`null` em 1, 4 e 7). Slug = nome em minúsculas sem acento.

| id  | name        | Elementos     | XP  | Altura (m) | Peso (kg) | Descrição (Bestiário)                                                                              |
| --- | ----------- | ------------- | --- | ---------- | --------- | -------------------------------------------------------------------------------------------------- |
| 1   | Fagulho     | Fogo          | 62  | 0.5        | 9.0       | Filhote de lobo com brasas no pelo. Quando se anima, solta faíscas pela cauda.                     |
| 2   | Brasalobo   | Fogo          | 142 | 1.0        | 32.0      | Corre pelas encostas vulcânicas. O pelo aquece tanto que seca a grama por onde passa.              |
| 3   | Infernolobo | Fogo / Sombra | 236 | 1.6        | 78.0      | Dizem que surge nos eclipses. Sua chama escurece até ficar negra diante de um rival digno.         |
| 4   | Gotículo    | Água          | 62  | 0.3        | 6.5       | Pequeno crustáceo que carrega uma gota de maré no casco. Sem ela, fica tímido e se esconde.        |
| 5   | Marisgarra  | Água          | 142 | 0.9        | 38.0      | Suas garras fecham com a força da maré cheia. Protege as poças onde nasceu.                        |
| 6   | Abissarra   | Água / Metal  | 236 | 1.5        | 160.0     | O casco endureceu nas profundezas até virar metal. Nenhuma corrente o tira do lugar.               |
| 7   | Brotelho    | Flora         | 62  | 0.4        | 4.2       | Filhote de lebre com um broto entre as orelhas. O broto se abre quando ele toma sol.               |
| 8   | Ramalebre   | Flora         | 142 | 0.9        | 18.5      | Salta entre os galhos mais altos. As orelhas viraram folhas que captam o vento.                    |
| 9   | Zefirama    | Flora / Vento | 236 | 1.4        | 42.0      | Guarda os bosques ventosos. Com um bater de orelhas, espalha sementes por quilômetros.             |

- **RF-02:** `species_elements.json`: 12 linhas, a partir da coluna Elementos (primeiro = `slot` 1).
- **RF-03:** `species_stats.json`: 54 linhas (9 espécies × 6 stats). Fogo do GDD; Água e Flora _a revisar_. O número entre parênteses é o `training_yield`; os outros stats têm 0.

| Espécie     | HP  | Atq     | Def     | Atq.E   | Def.E | Vel     | Total |
| ----------- | --- | ------- | ------- | ------- | ----- | ------- | ----- |
| Fagulho     | 44  | 58      | 42      | 60      | 48    | 66 (1)  | 318   |
| Brasalobo   | 60  | 78      | 56      | 80      | 62    | 84 (2)  | 420   |
| Infernolobo | 78  | 108 (3) | 72      | 100     | 76    | 101     | 535   |
| Gotículo    | 54  | 52      | 62 (1)  | 46      | 58    | 46      | 318   |
| Marisgarra  | 70  | 70      | 82 (2)  | 60      | 76    | 62      | 420   |
| Abissarra   | 92  | 96      | 110 (3) | 72      | 98    | 64      | 532   |
| Brotelho    | 46  | 44      | 48      | 64 (1)  | 56    | 60      | 318   |
| Ramalebre   | 60  | 56      | 62      | 84 (2)  | 74    | 84      | 420   |
| Zefirama    | 76  | 70      | 76      | 112 (3) | 94    | 104     | 532   |

**Traços**

- **RF-04:** `traits.json` (os de Fogo e Casca Dura são do GDD; os outros _a revisar_):

| id  | slug           | name          | description                                                          |
| --- | -------------- | ------------- | -------------------------------------------------------------------- |
| 1   | `blazing_fury` | Fúria Ardente | Técnicas de Fogo causam 50% a mais com o HP em 1/3 ou menos.         |
| 2   | `instinct`     | Instinto      | Ganha +1 de Velocidade ao derrotar um inimigo.                       |
| 3   | `tidal_fury`   | Maré Furiosa  | Técnicas de Água causam 50% a mais com o HP em 1/3 ou menos.         |
| 4   | `hard_shell`   | Casca Dura    | Não recebe golpes críticos.                                          |
| 5   | `rooted_fury`  | Raiz Furiosa  | Técnicas de Flora causam 50% a mais com o HP em 1/3 ou menos.        |
| 6   | `tailwind`     | Brisa Ligeira | Ganha +1 de Velocidade ao entrar em batalha.                         |

- **RF-05:** `species_traits.json`: 18 linhas. Cada espécie tem o traço normal da linha no `slot` 1 e o oculto no `slot` 3 (`is_hidden = true`): Fogo 1 e 2; Água 3 e 4; Flora 5 e 6.

**Técnicas**

- **RF-06:** `skills.json` com as 38 técnicas abaixo. As marcadas com † são do GDD; as outras _a revisar_. Colunas não mostradas: `priority` 0, `crit_stage` 0, `min_hits` = `max_hits` = 1, salvo indicação. Alvo: Inimigo, salvo "Si mesmo". Precisão 0 = nunca erra.

| id  | name                   | Elemento | Cat.     | Poder | Prec. | PP  | Contato | Outros / efeitos (`skill_effects`)          |
| --- | ---------------------- | -------- | -------- | ----- | ----- | --- | ------- | ------------------------------------------- |
| 1   | Arranhão †             | Fera     | Física   | 40    | 100   | 35  | sim     | —                                           |
| 2   | Rugido Feroz †         | Fera     | Suporte  | 0     | 100   | 30  | não     | −1 Atq do inimigo                           |
| 3   | Investida Veloz †      | Fera     | Física   | 40    | 100   | 30  | sim     | prioridade +1                               |
| 4   | Uivo †                 | Fera     | Suporte  | 0     | 0     | 40  | não     | Si mesmo; +1 Atq                            |
| 5   | Faísca Rápida †        | Fogo     | Especial | 40    | 100   | 25  | não     | 10% Queimado                                |
| 6   | Mordida Brasa †        | Fogo     | Física   | 60    | 100   | 20  | sim     | 10% Queimado                                |
| 7   | Fumaça Densa †         | Fogo     | Suporte  | 0     | 100   | 20  | não     | −1 Precisão do inimigo                      |
| 8   | Presa Ígnea †          | Fogo     | Física   | 65    | 95    | 15  | sim     | 10% Queimado                                |
| 9   | Chama Espiral †        | Fogo     | Especial | 90    | 100   | 15  | não     | 10% Queimado                                |
| 10  | Couraça de Cinzas †    | Fogo     | Suporte  | 0     | 0     | 20  | não     | Si mesmo; +1 Def; +1 Def.E                  |
| 11  | Lâmina Sombria †       | Sombra   | Física   | 70    | 100   | 15  | sim     | crítico alto                                |
| 12  | Garra do Eclipse †     | Sombra   | Física   | 90    | 100   | 10  | sim     | —                                           |
| 13  | Erupção Solar †        | Fogo     | Especial | 120   | 85    | 5   | não     | Recuo 33%                                   |
| 14  | Beliscão               | Fera     | Física   | 40    | 100   | 35  | sim     | —                                           |
| 15  | Couraça †              | Metal    | Suporte  | 0     | 0     | 20  | não     | Si mesmo; +1 Def                            |
| 16  | Jato de Maré †         | Água     | Especial | 40    | 100   | 25  | não     | —                                           |
| 17  | Espuma Densa           | Água     | Suporte  | 0     | 95    | 20  | não     | −1 Vel do inimigo                           |
| 18  | Garra de Maré          | Água     | Física   | 60    | 100   | 20  | sim     | —                                           |
| 19  | Casca Fechada          | Água     | Suporte  | 0     | 0     | 10  | não     | Si mesmo; prioridade +4; Proteger           |
| 20  | Lâmina d'Água          | Água     | Física   | 65    | 100   | 15  | sim     | crítico alto                                |
| 21  | Maré Restauradora      | Água     | Suporte  | 0     | 0     | 10  | não     | Si mesmo; Curar 50%                         |
| 22  | Torrente               | Água     | Especial | 90    | 100   | 15  | não     | —                                           |
| 23  | Pinça de Aço           | Metal    | Física   | 70    | 95    | 15  | sim     | 20% −1 Def do inimigo                       |
| 24  | Muralha de Coral       | Água     | Suporte  | 0     | 0     | 20  | não     | Si mesmo; +1 Def; +1 Def.E                  |
| 25  | Martelo de Ferro       | Metal    | Física   | 90    | 95    | 10  | sim     | —                                           |
| 26  | Maremoto               | Água     | Especial | 120   | 85    | 5   | não     | Recuo 33%                                   |
| 27  | Patada                 | Fera     | Física   | 40    | 100   | 35  | sim     | —                                           |
| 28  | Olhar Manhoso          | Fera     | Suporte  | 0     | 100   | 30  | não     | −1 Def do inimigo                           |
| 29  | Chicote de Raiz †      | Flora    | Física   | 45    | 100   | 25  | sim     | —                                           |
| 30  | Esporos Sonolentos     | Flora    | Suporte  | 0     | 75    | 15  | não     | Adormecido (100%)                           |
| 31  | Seiva Vital †          | Flora    | Especial | 60    | 100   | 15  | não     | Drenar 50%                                  |
| 32  | Folha Navalha          | Flora    | Especial | 60    | 100   | 20  | não     | crítico alto                                |
| 33  | Banho de Sol           | Flora    | Suporte  | 0     | 0     | 10  | não     | Si mesmo; Curar 50%                         |
| 34  | Tempestade de Pétalas  | Flora    | Especial | 90    | 100   | 15  | não     | —                                           |
| 35  | Lufada Cortante        | Vento    | Especial | 70    | 100   | 15  | não     | —                                           |
| 36  | Dança do Vento         | Vento    | Suporte  | 0     | 0     | 20  | não     | Si mesmo; +1 Atq.E; +1 Vel                  |
| 37  | Ciclone                | Vento    | Especial | 90    | 95    | 10  | não     | 20% Amedrontar                              |
| 38  | Explosão Florida       | Flora    | Especial | 120   | 85    | 5   | não     | Recuo 33%                                   |

Mordida Brasa, Fumaça Densa, Presa Ígnea, Uivo, Couraça de Cinzas e Garra do Eclipse aparecem no learnset do GDD sem todos os números; os que faltavam foram completados no planejamento.

- **RF-07:** Slug de cada técnica: o nome sem acento, em minúsculas, com `_` no lugar de espaço e apóstrofo (`lamina_d_agua`). Cada técnica tem uma `description` de uma frase em pt-BR, escrita na implementação, que diga o que ela faz em jogo.
- **RF-08:** `skill_effects.json`: uma linha por efeito da coluna "efeitos" (Proteger, Curar, Drenar, Recuo, Amedrontar, status e cada alteração de atributo). "Crítico alto" e "prioridade" são colunas de `skills`, não efeitos. Efeitos sem chance escrita têm `chance` 100. Em `modify_stat`, `skill_target_id` é o alvo do efeito (Inimigo ou Si mesmo).

**Learnsets**

- **RF-09:** `species_skills.json`, todas com `level_up`, exceto as linhas "Ao ascender" (`evolution`, nível 0). Fogo segue o GDD; Água e Flora _a revisar_. Nível 1: as duas técnicas de cada linha.

| Nível          | Fagulho / Brasalobo / Infernolobo     | Gotículo / Marisgarra / Abissarra   | Brotelho / Ramalebre / Zefirama        |
| -------------- | ------------------------------------- | ----------------------------------- | -------------------------------------- |
| 1              | Arranhão, Rugido Feroz                | Beliscão, Couraça                   | Patada, Olhar Manhoso                  |
| Ao ascender    | — / Mordida Brasa / Lâmina Sombria    | — / Garra de Maré / Pinça de Aço    | — / Folha Navalha / Lufada Cortante    |
| 7              | Faísca Rápida                         | Jato de Maré                        | Chicote de Raiz                        |
| 10             | Investida Veloz                       | Espuma Densa                        | Investida Veloz                        |
| 13             | Fumaça Densa                          | Casca Fechada                       | Esporos Sonolentos                     |
| 19             | Presa Ígnea                           | Lâmina d'Água                       | Seiva Vital                            |
| 25             | Uivo                                  | Maré Restauradora                   | Banho de Sol                           |
| 31 (só a base) | Chama Espiral                         | Torrente                            | Tempestade de Pétalas                  |
| 34 (2ª e 3ª)   | Chama Espiral                         | Torrente                            | Tempestade de Pétalas                  |
| 42 (2ª e 3ª)   | Couraça de Cinzas                     | Muralha de Coral                    | Dança do Vento                         |
| 48 (só a 3ª)   | Garra do Eclipse                      | Martelo de Ferro                    | Ciclone                                |
| 55 (2ª e 3ª)   | Erupção Solar                         | Maremoto                            | Explosão Florida                       |

Linhas sem indicação valem para as três formas. Total: 93 linhas (8 por forma base, 11 por forma do meio, 12 por forma final).

**Ascensões e iniciais**

- **RF-10:** `evolutions.json`: 6 regras com o gatilho `level`: 1 → 2 e 4 → 5 e 7 → 8 no nível 16; 2 → 3 e 5 → 6 e 8 → 9 no nível 36. Demais colunas `null`.
- **RF-11:** `starter_options.json`: Fagulho (`sort_order` 1), Gotículo (2), Brotelho (3).

## Critérios de aceite

- [x] O validador termina com "Catálogo OK" e código 0.
- [x] Um script temporário confere: `GameData.get_starters()` devolve Fagulho, Gotículo e Brotelho, nessa ordem; `get_species(3).element_ids` = `[1, 11]`; `get_species(1).base_stats.total()` = 318; `get_learnset(2)` começa com Mordida Brasa (nível 0); `get_evolutions(1)` tem uma regra para a espécie 2 no nível 16. (Apagar depois.)
- [x] `get_skill(13).effects` tem um efeito `recoil` com `percent` 33; `get_skill(36).effects` tem dois `modify_stat` em Si mesmo.
- [x] Nenhum nome de espécie, técnica ou traço é igual ou parecido com nomes do Pokémon.

O modo `--script` não carrega autoloads, então o script temporário usou um `Catalog` carregado pela mesma fonte (o `GameData` só repassa as consultas para ele). Ele também conferiu os totais de stats das 9 espécies e o tamanho dos learnsets (8, 11 e 12 por linha). Arranhão e Investida Veloz são palavras comuns em português e vêm do GDD; ficam na revisão do dono, junto com o resto.

## Desenho técnico

**Alterar**

- Os 10 arquivos de `res://data/` listados no Escopo.
- `.specs/game-data/README.md`: se o dono já tiver revisado as propostas, remover as marcas _a revisar_ correspondentes desta spec.

Nenhum código novo, como na fase 02.

## Verificação

```bash
godot --headless --path client --script res://tools/validate_data.gd ; echo "saída: $?"
```

E os critérios de aceite.

## Tarefas

- [x] `traits` e `skills` (com descrições) e `skill_effects`.
- [x] `species`, `species_elements`, `species_stats`.
- [x] `species_traits`, `species_skills`.
- [x] `evolutions` e `starter_options`.
- [x] Rodar o validador até "Catálogo OK".
- [x] Marcar esta spec e as tabelas como `concluída`; commit `feat: linhas iniciais no catálogo`.

## Dúvidas em aberto

- **Revisão do dono:** nomes, conceito, stats, traços e técnicas das linhas de Água e Flora; os 6 números completados da linha de Fogo.
- **Proporção de gênero dos iniciais:** 0.5 por padrão; o dono pode querer outra.
