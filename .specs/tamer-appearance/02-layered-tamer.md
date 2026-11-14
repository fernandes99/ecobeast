# 02. O Domador em camadas

- **Status:** concluída
- **Depende de:** [01-appearance-records](01-appearance-records.md)

## Contexto

Com a aparência no servidor (fase 1), o jogo passa a montar o Domador com ela: o corpo escolhido, com a cor da pele, e cada peça vestida por cima, com a sua cor. Hoje o `TamerSprite` (`res://ui/components/tamer_sprite.gd`) carrega uma folha só, e só o mapa de Explorar o usa (`res://screens/exploration/exploration_screen.gd`).

## Escopo

- A pasta da arte do [architecture](architecture.md#a-arte), com o corpo de hoje em `bodies/male/`.
- O shader de troca de paleta.
- O `TamerSprite` montado pela aparência do jogador, com as camadas da frente, as de trás e a regra do chapéu.
- Arte provisória para testar: o corpo de hoje pintado com as cores-chave na pele, e o rosto 1.

## Fora do escopo

- A tela Aparência (fase 3) e o guarda-roupa inicial (fase 4).
- O corpo feminino de verdade: até a fase 4, `bodies/female/` pode ser uma cópia do masculino.

## Requisitos

- **RF-01:** O Domador no mapa é desenhado com o corpo, a pele e as peças da aparência do jogador.
- **RF-02:** As camadas mudam de animação, de quadro e de espelho junto com o corpo, sem nenhum quadro de atraso.
- **RF-03:** A folha `_back` de uma peça é desenhada atrás do corpo; as outras, por cima, na ordem do `layer` do lugar.
- **RF-04:** Com um chapéu de `hair_cut` `top`, o cabelo usa as folhas `_short`, se existirem; com `all`, o cabelo não aparece.
- **RF-05:** Cada cor-chave de uma camada com paleta vira a cor do mesmo tom da paleta; as outras cores não mudam.
- **RF-06:** Uma peça sem as folhas obrigatórias não é desenhada e não trava o jogo.
- **RF-07:** As folhas de cada arquivo são montadas uma vez por execução, não a cada Domador criado.

## Critérios de aceite

Os quatro são passos manuais no mapa e ficam para o dono; a montagem das camadas, a troca de cor e as folhas `_back` foram conferidas na prévia da tela Aparência.

- [ ] No mapa de Explorar, o Domador aparece com a aparência do jogador, com a pele na cor da paleta.
- [ ] Trocar a paleta de pele e reabrir o mapa muda a cor da pele, e só ela.
- [ ] Andando nas 6 direções, nenhuma camada sai do lugar nem pisca.
- [ ] Uma peça com folha `_back` aparece atrás do corpo de costas e de frente.

## Desenho técnico

- `res://assets/tamer/`: `idle.png` e `run.png` vão para `template/`, sem mudança, e o `make_wardrobe.gd` gera dele `bodies/male/` e `bodies/female/` (a pele nas cores-chave e os olhos tirados para o rosto) e as peças de `parts/` (fase 4). Divergência: a spec dizia repintar o corpo à mão; com o gerador, o template fica como fonte e a arte provisória se refaz com um comando. `CREDITOS.md` explica a origem de cada folha.
- O `TamerSprite` nasce com a aparência padrão (`TamerAppearance.standard()`: corpo 1, pele 1 e rosto 1), o que vale para os Domadores NPC do mapa, e ganha `face_row(linha, espelhado)` para a prévia girar.
- `res://ui/components/palette_swap.gdshader` (novo): as 4 cores-chave como constantes e `uniform vec4 palette[4]`. Cada pixel igual a uma chave (com tolerância de meio tom em 8 bits) vira a cor do tom; os outros passam como estão.
- `res://ui/components/tamer_layer.gd` (novo): `TamerLayer`, um `AnimatedSprite2D` com as `SpriteFrames` de uma folha, que copia `animation`, `frame` e `flip_h` do pai.
- `res://ui/components/tamer_sprite.gd`: `set_appearance(appearance: TamerAppearance)`, que troca as `SpriteFrames` do corpo e recria os filhos; as `SpriteFrames` em cache por caminho de arquivo. `SheetSprite._add_sheet` passa a poder montar `SpriteFrames` para outro sprite, para o `TamerLayer` reusar.
- `res://screens/exploration/exploration_screen.gd`: chama `set_appearance` com a aparência de `Session.player`.

## Verificação

- O projeto abre no editor sem erros nem avisos de script.
- O jogo sem janela (`godot --headless --path client --quit-after 30`) não mostra erro.
- Passos manuais (F5): os critérios de aceite, no mapa sorteado e numa ilha.

## Tarefas

- [x] Mover e repintar o corpo; criar o rosto 1 provisório.
- [x] O shader de paleta.
- [x] `TamerLayer` e o `TamerSprite` com `set_appearance`.
- [x] Ligar no mapa de Explorar e conferir os passos manuais.
