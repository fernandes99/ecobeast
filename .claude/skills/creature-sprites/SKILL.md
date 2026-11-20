---
name: creature-sprites
description: Cria as folhas de pixel art idle.png e walk.png de um Ecobeast a partir do front.png dele, em 5 ângulos, no formato de client/assets/tamer. Use sempre que o usuário pedir sprite animado, idle, walk, andar, pixel art ou spritesheet de uma criatura ou Ecobeast (Ruvo, Nilu, Seedlet, Ruvak e os outros), mesmo sem dizer "folha", e também para ajustar ou redesenhar uma folha que já existe.
---

# Folhas de pixel art dos Ecobeasts

Esta skill transforma o `front.png` de um Ecobeast em duas folhas desenhadas à mão, pixel a pixel. Um `front.png` mostra um ângulo só, e reduzir a imagem borra e não cria os outros quatro. Por isso cada parte da criatura é um desenho em texto, e o código só monta as partes em cada quadro. Os exemplos estão em `client/assets/creatures/<slug>/explore/sprites.py`: leia o mais parecido antes de começar. Nilu é o menor; Ruvo é pequeno, de quatro patas; Ruvak é médio; Ruvaroth é grande; Puffcoo e Galecrest são aves; Nilgar e Nilgorr são caranguejos.

O tamanho vem da altura do catálogo, pela regra do mapa (`.specs/creature-scale/`): a escala do Domador mais 4 pixels, para os filhotes ficarem legíveis. Fale com o dono em pt-BR. Ele é iniciante em Godot, então explique os conceitos do motor quando aparecerem.

## Formato

| Folha       | Tamanho | Quadros | Ritmo no jogo                                 |
| ----------- | ------- | ------- | --------------------------------------------- |
| `idle.png`  | 128×160 | 4       | 0,8 s por ciclo, como o idle do Domador       |
| `walk.png`  | 192×160 | 6       | 0,6 s por ciclo, no formato de `run.png`      |

- Células de 32×32, em 5 linhas: frente, diagonal descendo para a direita, lado direito, diagonal subindo para a direita e costas. O lado esquerdo sai espelhando no jogo, com `flip_h`, então nunca é desenhado.
- Os pés encostam na última linha da célula, perto da coluna 16: é o ponto que o jogo põe no centro do hexágono.
- **Altura:** `pixels = arredondar(height_m × 25 / 1,70 + 4)`, no mínimo 6 e no máximo 32 (`height_in_pixels` do `spritekit.py`). O Domador tem 1,70 m e 25 pixels, e todo Ecobeast ganha 4 pixels a mais que essa escala. `height_m` está no catálogo (`GET /v1/catalog`, que o `check_sheets.py` lê; o `server/prisma/seed-data/` é só a carga inicial), e `weight_kg` diz se o corpo é esguio ou pesado. Hoje: Nilu, Puffcoo, Hushling e Lume 8, Seedlet, Tidebud e Clod 10, Ruvo 11, Nilgar e Owlume 17, Ruvak, Grovequill e Crag 19, Kelpcoil 20, Nilgorr, Galecrest e Noclume 26, Ruvaroth e Ingot 28, Echofrost 29, Arbornix 30 e Tempestide 32. A partir de uns 1,90 m, tudo tem 32 pixels, a altura da célula: nada sobe acima da primeira linha, então o balanço do idle desce, nunca sobe.
- **Largura:** até 32 pixels em todo quadro. Uma criatura que passaria disso, como o Ruvaroth e o Nilgorr, fica mais compacta, com a cauda, a chama e as pinças mais perto do corpo, e nunca cortada.
- A altura é da folha inteira, com orelhas e chamas. A verificação aceita 1 pixel de diferença.
- Sem transparência parcial, com até 16 cores, de preferência (a conferência barra acima de 32), e a mesma densidade de pixels do Domador.

## Passos

Os comandos rodam na raiz do repositório. `S` é `.claude/skills/creature-sprites/scripts`, `<criatura>` é `client/assets/creatures/<slug>`, `<pasta>` é `<criatura>/explore` (as folhas do mapa; as da luta ficam em `<criatura>/battle`, veja a seção no fim) e `<prévias>` é uma pasta temporária, fora do projeto. Rode o Python com `-I`.

1. **Olhe a criatura.** Sem `front.png` ainda, corte a imagem da linha que o dono mandou (guardada em `art-source/<slug da primeira forma>/line.webp`) com `python -I S/crop_line.py <imagem> <slug> [<slug> ...]`, os slugs da esquerda para a direita. Ele aceita a imagem com fundo transparente ou com fundo de uma cor lisa, como o verde do prompt da skill `creature-front-prompt`, que tira pela cor dos cantos. Abra `<criatura>/front.png` com a ferramenta Read e rode `python -I S/reference.py <criatura>/front.png <prévias>/referencia.png`. Abra a redução: ela mostra as proporções e lista as cores.
2. **Calcule a altura e liste o que a torna reconhecível.** Antes de desenhar, escreva para si: a altura em pixels, a anatomia (quantas patas, como se apoia), a silhueta, os olhos, as cores e o traço marcante, como a chama do Ruvo. Quanto menor a altura, menos cabe: escolha o que precisa sobreviver. O dono quer reconhecer a criatura, não um boneco genérico recolorido.
3. **Desenhe** `<pasta>/sprites.py`, copiando a estrutura do exemplo mais parecido: paleta tirada do `front.png`, cabeça e corpo para cada ângulo, patas e traços marcantes, tudo entregue a `rig`, que monta o idle e o walk. `recolored` tira o rosto para as vistas de costas, e `swayed` gera os 4 quadros de chama, folha ou água. Desenhe do zero o que for da criatura. Só o `spritekit` e a estrutura se repetem. Para o contorno, passe `outline={"*": "<chave escura>", ...}` ao `build`: ele contorna a silhueta por fora em cada quadro, com a cor escura de cada parte, e o desenho fica 2 pixels mais baixo que a altura pedida (os 6 pequenos, como a Nilu e o Ruvo, fazem assim). Para crescer uma folha que já existe sem trocar o desenho, `stretched(desenho, rows=..., cols=...)` repete linhas e colunas lisas de uma parte (os médios e os grandes, como o Ruvak e o Ruvaroth).
4. **Gere e olhe.** Rode `python -I <pasta>/sprites.py <prévias>/previa` e abra `idle_quadros.png` e `walk_quadros.png`. A primeira versão quase nunca fica boa: conte com duas ou três rodadas, corrigindo o que você vê.
5. **Confira.** Com o servidor no ar (`cd server && npm run start:dev`; é dele que vem a altura), rode `python -I S/check_sheets.py <pasta>`. Com a saída diferente de zero, conserte e gere de novo.
6. **Importe no Godot:** `godot --headless --path client --import`. Isso cria os `.import`, que vão para o repositório junto com as folhas. O Godot fica em `/c/Godot/Godot_v4.7.2-stable_win64_console.exe`.
7. **Entregue.** Diga onde estão as folhas e os GIFs de prévia, que mostram o movimento fora do jogo, com o caminho completo. Para ver no jogo, é só o dono rodar com F5, abrir Explorar zona e tocar em "Debug": quem tem as duas folhas fica ativo no spawn, sem mudar código. Diga também o que não foi visto rodando. Só commite se o dono pedir.

## Como desenhar

**Partes separadas.** Cabeça, corpo, patas e cada traço marcante são desenhos próprios. No `draw`, a ordem de carimbar é a profundidade: quem vem depois fica por cima. O que fica atrás da criatura na frente fica na frente dela nas costas, como a cauda do Ruvo.

**Acabamento, em qualquer tamanho.** A referência é a dos animais do pacote Fantasy Dreamland Reborn, que o dono escolheu: um pintinho de 10 a 12 pixels com 8 cores, legível de longe. Nenhum pixel do pacote entra numa folha: ele é só a régua de tamanho e de acabamento.
- Contorno de 1 pixel em toda a silhueta, escuro e puxado para a cor da parte (marrom no laranja, azul-marinho no azul, verde-escuro na folha), nunca preto puro. Ele entra também entre partes que se cobrem, como a cabeça na frente do corpo.
- Cada material com até 3 tons: luz em cima, base e sombra embaixo. A luz vem de cima.
- Até uns 14 pixels, cada olho é 1 pixel escuro, ou 1×2 nos maiores desse grupo; acima disso, olhos maiores com brilho. A cabeça de um filhote é grande para o corpo, e uma evolução fica mais alta e com a cabeça menor.
- Abaixo de 10 pixels, a cabeça nem desce, porque cobriria os pés: quem se mexe são as patas e o traço marcante. Os rascunhos de frente da Nilu (8), do Seedlet (10) e do Ruvo (11), aprovados pelo dono, estão em `art-source/creature-scale/front_drafts.py`.

**Idle.** Copie o ritmo do Domador: a cabeça desce 0, 1, 2 e 0 pixels, o corpo 0, 1, 1 e 0, e os pés ficam presos. Em uma criatura pequena, 2 pixels é demais: a cabeça desce 0, 1, 1 e 0, e o corpo fica parado. Sempre que a criatura tiver algo vivo, como chama, água ou folhas, mude isso a cada quadro: é o que impede o quarto quadro de repetir o primeiro.

**Walk.** Cada pata é desenhada por posição, com `draw_leg`, a partir de duas listas de 6 valores: quanto o pé está à frente do quadril e quanto está fora do chão. Com os valores do Ruvo, o pé fica 4 quadros no chão, andando para trás, e 2 no ar.

| Anatomia    | Como andar                                                                              |
| ----------- | --------------------------------------------------------------------------------------- |
| Quatro patas | Diagonais juntas: traseira de perto com dianteira de longe, com 3 quadros de diferença |
| Duas patas  | As duas pernas com 3 quadros de diferença, com o corpo balançando mais                  |
| Mais patas  | Lados alternados, em grupos, com passos curtos, como um caranguejo                      |
| Sem patas   | O corpo ondula ou encolhe e estica, sempre encostado no chão: a verificação exige algo na última linha em todo quadro. O Tidebud, o Kelpcoil e o Tempestide flutuam em pé, com `rig` sem patas, a cauda enrolada no chão como traço preso e a parte de cima balançando |

O corpo fica 1 pixel mais baixo nos quadros 0 e 3, com os pés mais abertos, e a cabeça chega um quadro depois. Em uma criatura pequena, só a cabeça desce: descer o corpo esconde as patas, e ela parece deitar. Uma lista com menos de 6 valores precisa emendar: a chama do Ruvo usa 0, 1, 2, 3, 2 e 1.

## O que deu errado no Ruvo

Confira isto nas prévias, porque são erros que os scripts não pegam. Os da lista vieram de uma primeira versão com 24 pixels, fora de escala, e valem para criaturas grandes:

- **Parte solta:** a chama da cauda boiava longe do corpo. Ligue com uma peça, como `TAIL`.
- **Cabeça estreita:** com a largura do corpo, parece um personagem em pé. Alargue a cabeça.
- **Olhos pequenos ou sérios:** uma pálpebra reta de 3 pixels deixa a criatura brava. Olho redondo, de 4×4, com brilho do mesmo lado nos dois olhos, fica próximo do `front.png`.
- **Coleira:** uma linha de contorno entre a cabeça e o peito parece coleira. Deixe o peito emendar na cabeça.
- **Corpo fino de lado:** a cabeça cobre o corpo. Comece o corpo mais alto na vista de lado.
- **Chama sem contraste:** contorno vermelho na chama, e não o contorno escuro do corpo.
- **Fora de escala:** ela foi desenhada sem olhar a altura, e parecia maior que o Domador. Calcule pela regra antes de desenhar.
- **Água-viva:** um caranguejo de patas longas e pinças soltas parece uma água-viva. Patas curtas, base larga e pinças encostadas na frente do corpo.
- **Pata solta:** um vão entre o corpo e as patas passa em todos os scripts. Confira `legs_top` contra a última linha do corpo.

## Regras do projeto

- Só desenhos próprios, a partir do `front.png` do projeto: nenhuma imagem de fora, e nada de nomes ou visuais do Pokémon.
- Ligar a folha a uma tela, além do spawn de depuração e do mapa, é outra entrega, que nasce de uma spec em `.specs/`. Esta skill só cria as folhas.
- Para nascer no mapa de verdade, a espécie também precisa de linhas em `species_biomes`, no banco. Sem elas, ela só aparece no spawn de depuração. Avise o dono.
- Depois de mudar `spritekit.py`, gere as criaturas de novo e confira que as folhas não mudaram, pixel a pixel.

## Folhas da luta (`battle/`)

As folhas do tabuleiro da luta ficam em `<criatura>/battle/` e seguem o formato de `.specs/board-battle/07-battle-sprites.md`:

- `idle.png` tem 2 linhas, de frente (south) e de costas (north), ou 5, com mais south-east, east e north-east (board-battle/17): parado, o Ecobeast olha para o último passo;
- `walk.png` tem 3 linhas: a diagonal descendo (south-east), o lado (east) e a diagonal subindo (north-east), ou 5, com mais south e north, que o tabuleiro não usa;
- as células são quadradas, todas as vistas olham para a direita, e uma linha pode ter menos quadros que outra.

O jogo tira tudo da imagem, então não há arquivo de dados ao lado. Elas aparecem sem ampliar. Há dois jeitos de fazer essas folhas:

**1. Do PixelLab.** O dono gera o personagem no site, com a vista "low top-down", a animação de idle (south e north, e de preferência também east, south-east e north-east) e o walk (east, south-east e north-east, e de preferência também south e north). A ferramenta põe as vistas a mais de uma folha quando o zip tem todas elas. O zip vai para `art-source/<slug>/pixellab.zip`; para baixar pela API, a chave fica em `PIXELLAB_API_KEY` no `server/.env`. Depois, rode `python -I S/battle_sheets.py <slug>`. Um `art-source/<slug>/battle.json` troca a fonte de uma vista, por exemplo `{"idle": {"north": "rotation"}}` para usar a imagem parada. Gerar no PixelLab gasta os créditos do dono: só gere com o ok dele.

Quando o PixelLab exporta uma folha só (`<nome>.png` com um `<nome>.json` das linhas) e chega só o idle, rode `python -I S/idle_from_spritesheet.py <slug> <zip>` (board-battle/24): ele escreve só o `idle.png`, com as 5 vistas, na célula e na linha dos pés do `walk.png` que já existe. É assim com o Ruvak, que tem o idle do PixelLab e o walk do boneco; o `sprites.py` dele escreve só o walk.

**2. À mão, com o boneco de peças** (`S/puppet.py`). O Ecobeast é montado com elipsoides: cabeça, focinho, corpo, patas de dois ossos, cauda e chamas. O renderizador:
- vira o boneco para cada vista;
- pinta cada peça em 3 tons de uma rampa;
- desenha o contorno, vermelho nas chamas;
- cola por cima os carimbos dos olhos e do focinho.

O exemplo é `client/assets/creatures/ruvak/battle/sprites.py`; rode `python -I <criatura>/battle/sprites.py <prévias>` e abra `idle_quadros.png` e `walk_quadros.png`. As vistas saem coerentes entre si, e as animações só movem as peças:
- **idle:** a respiração, a cabeça e as chamas;
- **walk:** as patas em diagonais, como na tabela de "Walk".

Depois de gerar as folhas, importe no Godot (`godot --headless --path client --import`).
