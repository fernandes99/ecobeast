# 03. Escolha do inicial no layout do protótipo

- **Status:** concluída
- **Depende de:** [02-hub-layout](02-hub-layout.md), [onboarding/02](../onboarding/02-starter-selection.md)

## Contexto

A escolha do inicial ainda é a tela do MVP: três cartões empilhados, em cor lisa, sobre o fundo escuro. O dono gerou um protótipo da tela (`starter-prototype.png`, nesta pasta) e uma folha com as peças para recortar (`starter-assets.png`). Esta fase refaz a tela nesse visual: cenário da arena, logo, três cartões lado a lado, cada um com a moldura, a cena e o botão do seu Elemento. O comportamento não muda: tocar num cartão abre a confirmação, e a escolha continua indo para o servidor.

## Escopo

- Recorte das peças da folha para `res://assets/`.
- Layout novo da tela `starter_select` e do `StarterCard`.
- Ícone opcional no `ElementBadge`.
- Variações `NamePlatePanel` e `BannerPanel` no tema.

## Fora do escopo

- O painel de confirmação (RF-06 e RF-07 de [onboarding/02](../onboarding/02-starter-selection.md) continuam iguais).
- Arte de Elementos que não têm peça na folha (só Fogo, Água e Flora têm).
- Animações e sons.

## Requisitos

**Peças** — recortadas da folha, com transparência onde a peça não é retangular:

| Arquivo                                            | O que é                                                        |
| -------------------------------------------------- | -------------------------------------------------------------- |
| `res://assets/backgrounds/starter_select.webp`     | Cenário em retrato, 1080 × 1920                                |
| `res://assets/ui/logo.png`                         | Logo do jogo, recortado do protótipo (a folha não tem)         |
| `res://assets/ui/elements/<slug>/card_frame.png`   | Moldura do cartão                                              |
| `res://assets/ui/elements/<slug>/scene.webp`       | Cena do Elemento, com a base sumindo em transparência          |
| `res://assets/ui/elements/<slug>/icon.png`         | Moeda redonda com o símbolo do Elemento                        |
| `res://assets/ui/elements/<slug>/button.png`       | Pontas do botão, sem o texto da folha (o meio estica)          |

`<slug>` é o `elements.slug` do catálogo: `fire`, `water` e `flora`.

**Tela**

- **RF-01:** O cenário cobre a tela inteira e fica parado enquanto o conteúdo rola.
- **RF-02:** De cima para baixo: o logo; uma faixa de ponta a ponta da tela com o título "Escolha seu Ecobeast inicial" e o texto "Cada um tem um Elemento único. Escolha aquele que combina com o seu estilo de batalha!"; os cartões. Isso substitui o RF-04 de [onboarding/02](../onboarding/02-starter-selection.md).
- **RF-03:** Os cartões ficam lado a lado, com a mesma largura e a mesma altura, na ordem de `GameData.get_starters()`. Isso substitui o layout do RF-05 de [onboarding/02](../onboarding/02-starter-selection.md).
- **RF-04:** A tela continua sem botão de voltar (RF-08 de [onboarding/02](../onboarding/02-starter-selection.md)), embora o protótipo mostre um.

**Cartão**

- **RF-05:** A moldura do Elemento é o fundo do cartão e estica sem deformar os cantos.
- **RF-06:** No topo, a moeda do Elemento sobressai metade para fora do cartão. Abaixo dela, a cena do Elemento com a arte da espécie (`CreaturePortrait`) por cima.
- **RF-07:** Abaixo da arte: o nome da espécie numa placa escura hexagonal, o `ElementBadge` com o ícone, a descrição do Bestiário centralizada e o botão "Escolher" na cor do Elemento, sempre no pé do cartão.
- **RF-08:** O cartão inteiro é tocável (`TapPanel`), inclusive o botão, e o toque abre a confirmação.
- **RF-09:** Um Elemento sem as peças mostra o cartão em cor lisa com a borda na cor do Elemento e o botão padrão do tema, sem erro.

## Critérios de aceite

- [x] A captura (540 × 960) lado a lado com `starter-prototype.png` mostra a mesma organização: logo, faixa do título, três cartões em linha e a arena embaixo.
- [x] Fagulho, Gotículo e Brotelho aparecem nessa ordem, com a moldura, a moeda, a cena e o botão do seu Elemento.
- [x] Tocar no cartão ou no botão "Escolher" abre a confirmação da espécie certa, e "Voltar" a fecha sem escolher.
- [x] Nenhuma imagem contém texto além do logo.
- [x] Numa janela mais baixa (405 × 640), nada sai da tela: o stretch `expand` mantém a altura em 1280 e alarga a área, e os cartões acompanham a largura.
- [x] Um Elemento sem peças mostra o cartão em cor lisa, sem erro. (Conferir com uma cena temporária.)
- [x] O jogo roda sem erros de script e o editor não mostra avisos.

## Desenho técnico

**Criar**

- As peças da tabela acima, com mipmaps na importação.

**Alterar**

- `res://screens/starter_select/starter_select_screen.tscn`/`.gd`: cenário, logo, faixa e cartões em `HBoxContainer`. `%Subtitle` e o nome do Domador saem do script.
- `res://screens/starter_select/starter_card.tscn`/`.gd`: a estrutura nova e as peças por Elemento.
- `res://ui/components/element_badge.tscn`/`.gd`: `@export var show_icon`, desligado por padrão, para as outras telas não mudarem.
- `res://ui/theme/main_theme.tres`: `NamePlatePanel` e `BannerPanel`.
- `.specs/onboarding/02-starter-selection.md`: RF-04 e RF-05 apontam para esta fase.
- `.specs/visual-theme/README.md`: a tabela de ilustrações e a de fases.
- `client/CLAUDE.md`: as novas variações e os arquivos de ilustração.

**Reaproveitar**

- `TapPanel`, `CreaturePortrait`, `ElementBadge`, `SafeArea`, `StarterConfirmPanel`.

## Verificação

Com o servidor rodando:

```bash
godot --headless --path client --quit-after 30
```

Capturar a tela com o Movie Maker e comparar com `starter-prototype.png`. Passo do dono: F5 no editor e no celular.

## Tarefas

- [x] Recortar as peças.
- [x] Tema e `ElementBadge` com ícone.
- [x] `StarterCard` novo (RF-05 a RF-09).
- [x] Tela nova (RF-01 a RF-04).
- [x] Capturas e conferência dos critérios.
- [x] Documentos; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Nomes e descrições vêm do catálogo:** o protótipo mostra nomes e textos de exemplo (Pyrolyn, Aqualis, Leafon). Os cartões continuam mostrando Fagulho, Gotículo e Brotelho e as descrições do Bestiário, porque o catálogo é a fonte da verdade.
- **Sem botão de voltar:** a tela é a primeira depois de criar o Domador, e não há para onde voltar.
- **Confirmação mantida:** "Escolher" no cartão abre o painel de confirmação em vez de escolher direto, porque a escolha não pode ser desfeita.
- **Logo como imagem:** é a exceção à regra de não ter texto em imagem, porque é uma marca fixa, não um texto que muda.
- **Cenário composto:** a folha traz a arena em paisagem. O cenário usa a arena na largura da tela, ancorada embaixo, com o céu continuado até o topo e nuvens tiradas do `hub.png`, que ficam na borda da imagem e sobre um céu parecido. As do protótipo ficaram com borda retangular.
- **Botão visual:** o "Escolher" ignora o mouse, então o toque cai no `TapPanel` do cartão. Assim há um alvo de toque só, com o mesmo retorno do resto do cartão.
- **Rolagem:** a tela mantém o `ScrollContainer`, mas hoje ele não rola, porque o conteúdo tem 895 de altura e a viewport nunca fica abaixo de 1280.
- **Conferência** pela cena temporária (apagada no fim): capturas, janela de 405 × 640, cartão sem peças com uma espécie de mentira de Volt e toques simulados no botão, na arte e no "Voltar". O catálogo atual só tem espécies de Fogo, Água e Flora. O F5 e o teste no celular são do dono.
