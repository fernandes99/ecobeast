# 02. Os bipes na caixa de fala

- **Status:** concluída
- **Depende de:** [01](01-voice-catalog.md)

## Contexto

Com as vozes no catálogo ([01](01-voice-catalog.md)), falta o som e tocá-lo. A caixa de fala (`TamerGreetingPanel`) escreve o texto por um tween em `visible_characters`, a 60 letras por segundo. Esta fase gera os 6 sons, faz a caixa tocar a voz enquanto escreve, no ritmo da voz, e faz cada lugar que fala passar a voz de quem fala ([architecture](architecture.md#quem-fala-com-qual-voz)).

## Escopo

- O `make_voices.py` e os 6 `.wav`.
- O canal de áudio `Voices`.
- A voz no `TamerGreetingPanel`.
- A voz de quem fala nas cenas, na conversa com os NPCs da ilha e na fala dos Domadores NPC.

## Fora do escopo

- O F2 (fase 03).
- Volume nas opções, desligar a voz e a voz no log da luta.

## Requisitos

### Os sons

- **RF-01:** `client/assets/sounds/voices/make_voices.py` gera `narration.wav`, `tamer.wav`, `low.wav`, `medium.wav`, `high.wav` e `chirp.wav` ao lado dele, com os timbres da [architecture](architecture.md#as-tabelas) e o formato de [O som](architecture.md#o-som). Ele usa só a biblioteca padrão, e rodar de novo dá os mesmos bytes. O cabeçalho do script diz como rodar e onde mudar cada timbre, como o `compose.py`.
- **RF-02:** O `default_bus_layout.tres` ganha o canal `Voices`, a −8 dB, mandando para o `Master`.

### A caixa de fala

- **RF-03:** `TamerGreetingPanel.say(text: String, voice: Dictionary = {})`. Com uma voz, o texto aparece a `chars_per_second` dela; sem voz, aparece a 60, como hoje, e sem som.
- **RF-04:** Enquanto o texto aparece, a caixa toca um bipe pelas regras de [O som](architecture.md#o-som): a cada `letters_per_blip` letras (espaço e pontuação não contam), com `pitch_scale` variando pela `pitch_variation` e o ruído do índice da letra. O bipe toca num `AudioStreamPlayer` da caixa, no canal `Voices`, com `max_polyphony` 2, para um bipe não cortar o anterior. Se o tween pular várias letras num quadro só, toca um bipe só.
- **RF-05:** Tocar para completar a linha para os bipes na hora. Uma fala nova também para os bipes da anterior, e o `close()` também.

### Quem fala

- **RF-06:** No `StoryPlayer`, o `say` passa a voz de quem fala: `narration` com `speaker: null`, `tamer` com `"tamer"`, e a do NPC do ator nos outros casos (`GameData.get_voice` do `voice_id` do NPC). A mensagem de erro ao salvar a história fica sem voz.
- **RF-07:** Na conversa com um NPC da ilha (`ExplorationScreen._say_line`), a voz é a do NPC. Na fala do Domador NPC antes da luta (`_challenge`), a voz é `medium`.

## Critérios de aceite

- [ ] Na `liora_abertura`, a narração toca a voz suave, a cada 3 letras, calada nos espaços.
- [ ] No `avo_chega`, o avô fala grave e mais devagar; no `mira_reencontro`, a Mira fala aguda e mais rápido.
- [x] Tocar no meio de uma fala completa a linha, e o bipe para na hora.
- [ ] Conversar com um NPC da ilha toca a voz dele, e um Domador NPC fala com a Média.
- [x] A mesma fala, repetida, soa igual.
- [x] Rodar o `make_voices.py` de novo não muda os `.wav` (o `git status` fica limpo).
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:** `client/assets/sounds/voices/make_voices.py` e os 6 `.wav` (com os `.import` que o Godot gera).
- **Alterar:**
  - `client/default_bus_layout.tres`
  - `client/screens/exploration/tamer_greeting_panel.gd`: o tween passa a ser um `tween_method` sobre o número de letras, e um bipe toca quando o número de letras contadas passa de um múltiplo de `letters_per_blip`.
  - `client/screens/exploration/story_player.gd`
  - `client/screens/exploration/exploration_screen.gd`
- **Reutilizar:** o `GameData.get_voice` e o `GameData.voice_by_slug` da [01](01-voice-catalog.md).

## Notas da implementação

- Se o tween pular várias letras num quadro só, toca o primeiro bipe do trecho, para a letra 0 sempre soar.
- No fim do texto, o último bipe soa até acabar; só o toque, uma fala nova e o `close()` o cortam.
- A caixa emite `blipped(letter)` a cada bipe, para os testes.
- Uma letra é o caractere que muda entre maiúscula e minúscula (pega os acentos) ou um algarismo.
- O ruído da altura é um hash inteiro do índice da letra (`TamerGreetingPanel.pitch_noise`).
- O nome de quem fala, antes dos dois-pontos, também é escrito e conta letras, como antes.
- Conferido sem janela: a narração bipa nas letras 0, 3, 6 e 9 de "Olá, mundo! 123", a mesma fala repete os mesmos bipes, sem voz não bipa, e o toque corta o bipe. Falta o dono ouvir no F5.

## Verificação

- `python client/assets/sounds/voices/make_voices.py` duas vezes, com o `git status` limpo depois da segunda.
- `godot --headless --path client --quit-after 30`.
- Uma cena temporária toca falas com cada voz e confere quantos bipes tocaram e em quais letras. Ela fica fora de `client/zz_tmp_check`, que outra sessão usa, e é apagada depois.
- F5: as cenas de Liora, um NPC da ilha e um Domador NPC, ouvindo.

## Tarefas

- [x] O `make_voices.py` e os sons.
- [x] O canal `Voices`.
- [x] Os bipes no `TamerGreetingPanel`.
- [x] A voz de quem fala nas cenas, nos NPCs da ilha e nos Domadores NPC.
- [x] O `client/CLAUDE.md` e as tabelas das specs.
