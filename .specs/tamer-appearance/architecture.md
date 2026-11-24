# tamer-appearance: arquitetura

## A arte

Toda folha (corpo ou peça) segue o formato do `SheetSprite` (`res://ui/components/sheet_sprite.gd`), o mesmo das folhas de hoje:

- quadros de **32×32**, com o Domador de 16×32 no meio e os pés na borda de baixo;
- **5 linhas**, de cima para baixo: frente, diagonal de baixo, lado, diagonal de cima e costas. Nas três do meio, o Domador olha para a direita, e o jogo espelha para a esquerda;
- `idle.png` com **4 colunas** (128×160) e `run.png` com **6 colunas** (192×160).

Uma peça é transparente em tudo, menos nela mesma. Ela é desenhada por cima do corpo, num arquivo com camadas (Aseprite ou LibreSprite), e exportada camada por camada. Assim cada quadro da peça casa com o quadro do corpo.

```
res://assets/tamer/
  CREDITOS.md
  bodies/<slug do corpo>/idle.png, run.png
  parts/<slug da peça>/idle.png, run.png            obrigatórias
  parts/<slug da peça>/idle_back.png, run_back.png  opcionais: o que fica atrás do corpo
  parts/<slug da peça>/idle_short.png, run_short.png  opcionais, só cabelo: a versão achatada para chapéu
  parts/<slug da peça>/child/...                     as mesmas folhas no tamanho da criança (template/child/, o 16x16)
```

`idle.png` e `run.png` da raiz (o template da Eris Esra) passam para `template/`, e o `make_wardrobe.gd` gera deles os corpos e as peças provisórias ([fase 4](04-starter-wardrobe.md)).

### As cores-chave

As áreas que mudam de cor são pintadas com uma rampa de 4 cores-chave, da mais clara para a mais escura (_a revisar_):

| Tom | Cor-chave |
| --- | --- |
| 1 (luz) | `#E6E6E6` |
| 2 | `#B4B4B4` |
| 3 | `#828282` |
| 4 (sombra) | `#505050` |

O shader troca cada cor-chave pela cor do mesmo tom da paleta escolhida. Qualquer outra cor (contorno, olhos, fivela, detalhe) fica como foi desenhada. Um cinza que não deve mudar de cor precisa fugir das 4 chaves (por exemplo, `#828283`).

O corpo também é pintado com as cores-chave na pele, e a paleta de pele as troca. A roupa íntima do corpo tem cor fixa.

## O catálogo

**`body_types`**, os corpos:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | `^[a-z0-9_]+$`, único: a pasta `bodies/<slug>/` |
| `name` | text | pt-BR |
| `adult_body_type_id` | int, opcional | FK `body_types`, `Restrict`: o corpo de adulto cujas peças a criança veste. Nulo é adulto ([village-crowd/02](../village-crowd/02-children.md)) |

| id | slug | name | adult_body_type_id |
| --- | --- | --- | --- |
| 1 | `male` | Masculino | — |
| 2 | `female` | Feminino | — |
| 3 | `boy` | Menino | 1 |
| 4 | `girl` | Menina | 2 |

O corpo de criança é só de NPC: o `PUT /v1/me/appearance` o recusa com "Esse corpo é só de NPC.", e a tela Aparência só o mostra ao vestir um NPC. Uma peça serve num corpo quando o `body_type_id` dela é nulo, é o do corpo ou é o adulto dele.

**`appearance_slots`**, os lugares do corpo, na ordem de desenho:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | `^[a-z0-9_]+$`, único. O jogo conhece `hair` e `headwear` |
| `name` | text | pt-BR, o que a tela Aparência mostra |
| `layer` | int | ordem de desenho por cima do corpo, única, ≥ 1 |
| `palette_kind` | text, opcional | `skin`, `hair` ou `cloth`: o tipo de paleta que a peça aceita. Nulo é cor fixa |
| `required` | bool | o jogador não pode ficar sem peça nesse lugar |

| id | slug | name | layer | palette_kind | required |
| --- | --- | --- | --- | --- | --- |
| 1 | `face` | Rosto | 1 | — | sim |
| 2 | `bottom` | Parte de baixo | 2 | `cloth` | não |
| 3 | `shoes` | Calçado | 3 | `cloth` | não |
| 4 | `top` | Parte de cima | 4 | `cloth` | não |
| 5 | `hair` | Cabelo | 5 | `hair` | não |
| 6 | `headwear` | Chapéu | 6 | `cloth` | não |

**`appearance_parts`**, as peças:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | `^[a-z0-9_]+$`, único: a pasta `parts/<slug>/` |
| `name` | text | pt-BR |
| `appearance_slot_id` | int | FK `appearance_slots`, `Restrict` |
| `body_type_id` | int, opcional | FK `body_types`, `Restrict`; nulo serve nos dois corpos |
| `hair_cut` | text | `none`, `top` ou `all`, padrão `none`. Só o chapéu usa: o que ele esconde do cabelo |

**`palettes`**, as paletas de cor:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | `^[a-z0-9_]+$`, único |
| `name` | text | pt-BR |
| `kind` | text | `skin`, `hair` ou `cloth` |
| `color1_hex` … `color4_hex` | text | `^#[0-9a-f]{6}$`: a cor de cada tom, da luz à sombra |

As peças e as paletas iniciais estão na [fase 4](04-starter-wardrobe.md). A fase 1 traz só o necessário para a aparência padrão existir: os 2 corpos, os 6 lugares, 1 rosto (`face_1`, "Rosto 1") e 1 paleta de cada tipo.

## A aparência do jogador

`players` ganha `body_type_id` (FK `body_types`, padrão 1) e `skin_palette_id` (FK `palettes`, padrão a primeira de pele).

**`player_appearance_parts`**, uma peça vestida:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `player_id` | uuid | FK `players`, apaga junto |
| `appearance_slot_id` | int | FK `appearance_slots`, `Restrict` |
| `appearance_part_id` | int | FK `appearance_parts`, `Restrict` |
| `palette_id` | int, opcional | FK `palettes`, `Restrict` |

Chave `(player_id, appearance_slot_id)`: uma peça por lugar. O lugar se repete aqui, mesmo sendo o da peça, para a chave garantir isso no banco.

A migration dá a quem já existe o rosto 1, e o `POST /v1/me` cria o Domador com ele. A aparência padrão é o corpo 1, a primeira pele e o rosto 1.

## O contrato

`GET /v1/me` (e toda resposta com `player`) traz:

```json
"appearance": {
  "body_type_id": 1,
  "skin_palette_id": 2,
  "parts": [
    { "part_id": 1, "palette_id": null },
    { "part_id": 7, "palette_id": 12 }
  ]
}
```

`parts` vem na ordem do `layer` do lugar.

`PUT /v1/me/appearance` recebe o mesmo objeto e troca a aparência inteira. Recusa (`400`) com a mensagem do primeiro erro:

- "Esse corpo não existe.";
- "Essa cor de pele não existe." (paleta que falta ou que não é de pele);
- "A peça 9 não existe.";
- "A peça Saia não serve no corpo Masculino.";
- "Duas peças no mesmo lugar: Cabelo.";
- "Escolha um Rosto." (falta peça num lugar obrigatório);
- "Escolha uma cor para Cabelo." (o lugar tem `palette_kind` e a peça veio sem cor);
- "A cor 30 não serve para Cabelo." (a paleta não existe, não é do tipo do lugar, ou o lugar é de cor fixa).

Sem Domador, `409` "Crie seu Domador primeiro.", como as outras rotas de `/v1/me`.

## No jogo

- `TamerAppearance` (`res://domain/models/tamer_appearance.gd`) é a aparência lida do `Player`, com o corpo, a pele e as peças; `GameData` lê os 4 catálogos novos.
- O `TamerSprite` continua sendo o corpo, um `AnimatedSprite2D`. Para cada peça vestida, ele ganha um filho `TamerLayer` (outro `AnimatedSprite2D`) com as folhas da peça. O filho copia do pai a animação, o quadro e o espelho sempre que eles mudam (os sinais `animation_changed` e `frame_changed`). No Godot, um filho é desenhado por cima do pai e, entre irmãos, o último por cima; a ordem dos filhos é o `layer` do lugar.
- A folha `_back` vira outro `TamerLayer` com `show_behind_parent` ligado, que o desenha atrás do corpo.
- O chapéu com `hair_cut` `top` faz o cabelo usar as folhas `_short`, se existirem; sem elas, o cabelo inteiro. Com `all`, o cabelo não é desenhado.
- O shader `res://ui/components/palette_swap.gdshader` troca as cores-chave pelas 4 cores da paleta (um `ShaderMaterial` por camada com cor). Camada sem paleta não usa shader.
- As `SpriteFrames` de cada folha são montadas uma vez e guardadas num cache estático, como as do `TamerSprite` de hoje.
- Uma peça cujas folhas faltam não é desenhada; o visualizador (F1) a lista entre os arquivos que faltam.
