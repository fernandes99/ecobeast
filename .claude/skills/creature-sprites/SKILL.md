---
name: creature-sprites
description: Cria as folhas de pixel art idle.png e walk.png de um Ecobeast a partir do front.png dele, em 5 ângulos, no formato de client/assets/tamer. Use sempre que o usuário pedir sprite animado, idle, walk, andar, pixel art ou spritesheet de uma criatura ou Ecobeast (Ruvo, Nilu, Elu, Ruvak e os outros), mesmo sem dizer "folha", e também para ajustar ou redesenhar uma folha que já existe.
---

# Folhas de pixel art dos Ecobeasts

Esta skill transforma o `front.png` de um Ecobeast em duas folhas desenhadas à mão, pixel a pixel. Um `front.png` mostra um ângulo só, e reduzir a imagem borra e não cria os outros quatro. Por isso cada parte da criatura é um desenho em texto, e o código só monta as partes em cada quadro. Os exemplos estão em `client/assets/creatures/<slug>/sprites.py`: leia o mais parecido antes de começar. Nilu é o menor; Ruvo e Elu são pequenos, de quatro patas; Ruvak e Eluvin são médios; Ruvaroth e Eluvara são grandes; Nilgar e Nilgorr são caranguejos.

O tamanho vem da altura do catálogo, na escala do Domador: um Ecobeast pequeno é pequeno de verdade. Fale com o dono em pt-BR. Ele é iniciante em Godot, então explique os conceitos do motor quando aparecerem.

## Formato

| Folha       | Tamanho | Quadros | Ritmo no jogo                                 |
| ----------- | ------- | ------- | --------------------------------------------- |
| `idle.png`  | 128×160 | 4       | 0,8 s por ciclo, como o idle do Domador       |
| `walk.png`  | 192×160 | 6       | 0,6 s por ciclo, no formato de `run.png`      |

- Células de 32×32, em 5 linhas: frente, diagonal descendo para a direita, lado direito, diagonal subindo para a direita e costas. O lado esquerdo sai espelhando no jogo, com `flip_h`, então nunca é desenhado.
- Os pés encostam na última linha da célula, perto da coluna 16: é o ponto que o jogo põe no centro do hexágono.
- **Altura:** o Domador tem 1,70 m e ocupa 25 pixels, então `pixels = height_m × 25 / 1,70`, arredondado. `height_m` está em `server/prisma/seed-data/species.json`, e `weight_kg` diz se o corpo é esguio ou pesado. Hoje: Nilu 4, Elu 6, Ruvo 7, Nilgar e Eluvin 13, Ruvak 15, Eluvara 21, Nilgorr 22 e Ruvaroth 24. Qualquer altura até 2,18 m cabe na célula.
- A altura é da folha inteira, com orelhas e chamas. A verificação aceita 1 pixel de diferença.
- Sem transparência parcial, com até 32 cores e a mesma densidade de pixels do Domador.

## Passos

Os comandos rodam na raiz do repositório. `S` é `.claude/skills/creature-sprites/scripts`, `<pasta>` é `client/assets/creatures/<slug>` e `<prévias>` é uma pasta temporária, fora do projeto. Rode o Python com `-I`.

1. **Olhe a criatura.** Abra `<pasta>/front.png` com a ferramenta Read e rode `python -I S/reference.py <pasta>/front.png <prévias>/referencia.png`. Abra a redução: ela mostra as proporções e lista as cores.
2. **Calcule a altura e liste o que a torna reconhecível.** Antes de desenhar, escreva para si: a altura em pixels, a anatomia (quantas patas, como se apoia), a silhueta, os olhos, as cores e o traço marcante, como a chama do Ruvo. Quanto menor a altura, menos cabe: escolha o que precisa sobreviver. O dono quer reconhecer a criatura, não um boneco genérico recolorido.
3. **Desenhe** `<pasta>/sprites.py`, copiando a estrutura do exemplo mais parecido: paleta tirada do `front.png`, cabeça e corpo para cada ângulo, patas e traços marcantes, tudo entregue a `rig`, que monta o idle e o walk. `recolored` tira o rosto para as vistas de costas, e `swayed` gera os 4 quadros de chama, folha ou água. Desenhe do zero o que for da criatura. Só o `spritekit` e a estrutura se repetem.
4. **Gere e olhe.** Rode `python -I <pasta>/sprites.py <prévias>/previa` e abra `idle_quadros.png` e `walk_quadros.png`. A primeira versão quase nunca fica boa: conte com duas ou três rodadas, corrigindo o que você vê.
5. **Confira.** Rode `python -I S/check_sheets.py <pasta>`. Com a saída diferente de zero, conserte e gere de novo.
6. **Importe no Godot:** `godot --headless --path client --import`. Isso cria os `.import`, que vão para o repositório junto com as folhas. O Godot fica em `/c/Godot/Godot_v4.7.2-stable_win64_console.exe`.
7. **Entregue.** Diga onde estão as folhas e os GIFs de prévia, que mostram o movimento fora do jogo, com o caminho completo. Para ver no jogo, é só o dono rodar com F5, abrir Explorar zona e tocar em "Debug": quem tem as duas folhas fica ativo no spawn, sem mudar código. Diga também o que não foi visto rodando. Só commite se o dono pedir.

## Como desenhar

**Partes separadas.** Cabeça, corpo, patas e cada traço marcante são desenhos próprios. No `draw`, a ordem de carimbar é a profundidade: quem vem depois fica por cima. O que fica atrás da criatura na frente fica na frente dela nas costas, como a cauda do Ruvo.

**Até uns 12 pixels de altura.** Não há lugar para contorno: ele comeria o corpo, e quem separa as partes é a cor. Cada olho é um pixel, e cada pata é uma coluna. Fique com a silhueta e um traço marcante. Abaixo de 7 pixels, a cabeça nem desce, porque cobriria os pés: quem se mexe são as patas e o traço marcante.

**Acima disso.** Volte ao contorno escuro e aos olhos com brilho. A cabeça de um filhote é grande para o corpo, e uma evolução fica mais alta e com a cabeça menor.

**Idle.** Copie o ritmo do Domador: a cabeça desce 0, 1, 2 e 0 pixels, o corpo 0, 1, 1 e 0, e os pés ficam presos. Em uma criatura pequena, 2 pixels é demais: a cabeça desce 0, 1, 1 e 0, e o corpo fica parado. Sempre que a criatura tiver algo vivo, como chama, água ou folhas, mude isso a cada quadro: é o que impede o quarto quadro de repetir o primeiro.

**Walk.** Cada pata é desenhada por posição, com `draw_leg`, a partir de duas listas de 6 valores: quanto o pé está à frente do quadril e quanto está fora do chão. Com os valores do Ruvo, o pé fica 4 quadros no chão, andando para trás, e 2 no ar.

| Anatomia    | Como andar                                                                              |
| ----------- | --------------------------------------------------------------------------------------- |
| Quatro patas | Diagonais juntas: traseira de perto com dianteira de longe, com 3 quadros de diferença |
| Duas patas  | As duas pernas com 3 quadros de diferença, com o corpo balançando mais                  |
| Mais patas  | Lados alternados, em grupos, com passos curtos, como um caranguejo                      |
| Sem patas   | O corpo ondula ou encolhe e estica, sempre encostado no chão: a verificação exige algo na última linha em todo quadro |

O corpo fica 1 pixel mais baixo nos quadros 0 e 3, com os pés mais abertos, e a cabeça chega um quadro depois. Em uma criatura pequena, só a cabeça desce: descer o corpo esconde as patas, e ela parece deitar. Uma lista com menos de 6 valores precisa emendar: a chama do Ruvo usa 0, 1, 2, 3, 2 e 1.

## O que deu errado no Ruvo

Confira isto nas prévias, porque são erros que os scripts não pegam. Os da lista vieram de uma primeira versão com 24 pixels, fora de escala, e valem para criaturas grandes:

- **Parte solta:** a chama da cauda boiava longe do corpo. Ligue com uma peça, como `TAIL`.
- **Cabeça estreita:** com a largura do corpo, parece um personagem em pé. Alargue a cabeça.
- **Olhos pequenos ou sérios:** uma pálpebra reta de 3 pixels deixa a criatura brava. Olho redondo, de 4×4, com brilho do mesmo lado nos dois olhos, fica próximo do `front.png`.
- **Coleira:** uma linha de contorno entre a cabeça e o peito parece coleira. Deixe o peito emendar na cabeça.
- **Corpo fino de lado:** a cabeça cobre o corpo. Comece o corpo mais alto na vista de lado.
- **Chama sem contraste:** contorno vermelho na chama, e não o contorno escuro do corpo.
- **Fora de escala:** ela foi desenhada sem olhar a altura, e parecia maior que o Domador. Calcule antes de desenhar.
- **Água-viva:** um caranguejo de patas longas e pinças soltas parece uma água-viva. Patas curtas, base larga e pinças encostadas na frente do corpo.
- **Pata solta:** um vão entre o corpo e as patas passa em todos os scripts. Confira `legs_top` contra a última linha do corpo.

## Regras do projeto

- Só desenhos próprios, a partir do `front.png` do projeto: nenhuma imagem de fora, e nada de nomes ou visuais do Pokémon.
- Ligar a folha a uma tela, além do spawn de depuração e do mapa, é outra entrega, que nasce de uma spec em `.specs/`. Esta skill só cria as folhas.
- Para nascer no mapa de verdade, a espécie também precisa de linhas em `species_biomes`, no banco. Sem elas, ela só aparece no spawn de depuração. Avise o dono.
- Depois de mudar `spritekit.py`, gere as criaturas de novo e confira que as folhas não mudaram, pixel a pixel.
