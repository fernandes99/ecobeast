# dialogue-voices: arquitetura

## As tabelas

`voices`, no schema `ecobeasts`:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | único, `^[a-z0-9_]+$`; é o nome do arquivo `res://assets/sounds/voices/<slug>.wav` |
| `name` | text | o que o F2 mostra |
| `chars_per_second` | int | de 20 a 90: a velocidade do texto com essa voz |
| `letters_per_blip` | int | de 1 a 4: toca um bipe a cada tantas letras |
| `pitch_variation` | int | de 0 a 25: quanto a altura varia, em %, para cima ou para baixo |

`npcs` ganha `voice_id int not null references voices(id) on delete restrict`, que a migration preenche nos NPCs que já existem.

A carga inicial (`seed-data/voices.json`), com os valores da demonstração que o dono ouviu:

| id | slug | name | Timbre do arquivo | letras/s | letras/bipe | variação |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `narration` | Narração | triangular, 330 Hz, 50 ms | 50 | 3 | 4 |
| 2 | `tamer` | Domador | quadrada, 440 Hz, 35 ms | 60 | 2 | 5 |
| 3 | `low` | Grave | quadrada, 170 Hz, 55 ms | 42 | 3 | 5 |
| 4 | `medium` | Média | quadrada, 390 Hz, 40 ms | 52 | 2 | 4 |
| 5 | `high` | Aguda | pulso de 25%, 760 Hz, 30 ms | 66 | 2 | 10 |
| 6 | `chirp` | Pio | senoide subindo de 900 a 1.440 Hz, 70 ms | 40 | 3 | 12 |

As vozes dos NPCs que já existem: `village_ruvo` (1), `guard_ruvak` (2) e `liora_puffcoo` (6) com Pio; `grandpa` (3) com Grave; `mira` (4) com Aguda; `refuge_keeper` (5) com Média. Um NPC novo nasce com Média (`default 4` na coluna).

## Quem fala com qual voz

| Onde | Quem | Voz |
| --- | --- | --- |
| Cena, `say` com `speaker: null` | a narração | `narration` |
| Cena, `say` com `speaker: "tamer"` | o Domador | `tamer` |
| Cena, `say` com a `key` de um ator | o NPC do ator | `npcs.voice_id` dele |
| Conversa com um NPC da ilha | o NPC | `npcs.voice_id` dele |
| Fala do Domador NPC antes da luta | o Domador NPC | `medium` |
| Erro ao salvar a história | o jogo | nenhuma (sem som) |

## O som

Um bipe é o `.wav` inteiro da voz, tocado do começo. O `make_voices.py` (`client/assets/sounds/voices/`) gera os 6 arquivos com a biblioteca padrão do Python: mono, 22.050 Hz, 16 bits, com um ataque de 4 ms e um decaimento exponencial até o fim, como o `compose.py`. Rodar de novo dá os mesmos arquivos. Para mudar o timbre, muda-se o script; para mudar o ritmo, o catálogo.

A caixa de fala conta as letras que aparecem. Cada letra ou número (`\p{L}` ou `\p{N}`) conta 1, e espaço e pontuação contam 0. Toca um bipe na letra 0, na `letters_per_blip`, na `2 × letters_per_blip` e assim por diante. Cada bipe toca com `pitch_scale = 1 + v × ruído(i)`: `v` é `pitch_variation / 100`, e `ruído(i)`, de −1 a 1, depende só do índice da letra. Assim, a mesma fala soa igual.

## O que muda em cada lado

- **Servidor:** a migration, o `voices.json`, a coluna no `npcs.json`, a tabela em `CATALOG_TABLES` e a rota `PUT /v1/editor/npcs/:id/voice`.
- **Jogo:**
  - `GameData.get_voice(id)` e `GameData.voice_by_slug(slug)`;
  - a conferência do catálogo;
  - a voz no `TamerGreetingPanel.say`;
  - quem fala escolhe a voz (`StoryPlayer`, `ExplorationScreen`);
  - o canal `Voices` no `default_bus_layout.tres`;
  - o campo Voz da ferramenta NPC do F2.
