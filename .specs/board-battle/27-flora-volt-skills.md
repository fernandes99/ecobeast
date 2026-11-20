# 27. Ícone, efeito e som de três Técnicas de Flora e três de Volt

- **Status:** concluída (falta o dono ver e ouvir no jogo)
- **Depende de:** [26](26-feather-wind-skills.md) (o mesmo caminho)

## Contexto

Depois da [26](26-feather-wind-skills.md), o dono mandou, em 2026-11-19, a imagem com os ícones das próximas seis Técnicas sem ícone, em 3 colunas e 2 linhas, nessa ordem: Bicada de Folha, Garra de Espinho e Asa Semeadora (Flora, da [browt-line](../browt-line/)) e Faísca de Alga, Corrente Viva e Maré Elétrica (Volt, da [tidebud-line](../tidebud-line/02-volt-skills.md)). São as primeiras Técnicas de Volt com efeito.

## Escopo

- Os seis ícones, os seis efeitos, o projétil da Faísca de Alga e os seis sons.

## Fora do escopo

- Tempestade de Algas, Desabamento e Abalo Profundo, que ficam para quando o dono mandar os ícones.
- Mudar os dados das seis Técnicas no catálogo.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, recortados de `art-source/skills/flora_volt_icons.jpg` pelo `cut_icons.gd`. O ícone da Garra de Espinho tinha um quadrado preto de uns 12 px no meio da imagem do dono; Claude o preencheu com as cores em volta, depois do recorte.
- **RF-02:** O efeito de cada Técnica, escolhido por Claude pela forma e pelo ícone, na linha do Elemento da [18](18-element-skill-effects.md): a 4ª (verde) para Flora e a 1ª (laranja e amarelo) para Volt (_a revisar_):

  | Técnica | Alvo | Folha | Forma |
  | --- | --- | --- | --- |
  | Bicada de Folha | inimigo | 5/231 | uma bicada curta, em diagonal, que bate e some |
  | Garra de Espinho | inimigo | 3/126 | um arranhão curvo que rasga e se desfaz |
  | Asa Semeadora | inimigo | 11/527 | espinhos brotando do chão em moita |
  | Faísca de Alga | inimigo | 7/324 | faíscas que se cruzam num X e estalam |
  | Corrente Viva | inimigo | 4/195 | uma teia de raios correndo pela fileira |
  | Maré Elétrica | inimigo | 13/614 | um raio em zigue-zague que se enrola e some |

- **RF-03:** A Faísca de Alga (alcance 3, sem atravessar) ganha o projétil `faisca_de_alga_projectile.png`, da 1ª linha da `Part 12/579.png`, o mesmo risco da Pena Afiada ([26](26-feather-wind-skills.md)), em laranja e amarelo. As outras não têm projétil: a Corrente Viva atravessa a fileira e já corre por ela, e as Técnicas de Flora são de contato ou atravessam.
- **RF-04:** O som de cada Técnica, por síntese, sem gravação de terceiros, no `element_skills.py` (_a revisar_), com a peça nova `zap`, um zumbido elétrico:

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Bicada de Folha | 0,4 s | um farfalhar curto das folhas e a bicada seca, de madeira, com um baque leve |
  | Garra de Espinho | 0,6 s | o ramo de espinhos rangendo, três arranhões rápidos e o estalo dos espinhos cravando |
  | Asa Semeadora | 0,8 s | a batida larga da asa, as sementes chovendo em estalinhos e os espinhos brotando num ranger que sobe |
  | Faísca de Alga | 0,45 s | um estalo elétrico curto que chia e uma faísca aguda no fim |
  | Corrente Viva | 0,75 s | a água correndo e uma corrente que zumbe e sobe de altura, com estalos pelo caminho |
  | Maré Elétrica | 0,8 s | uma onda baixa que se espalha e um zumbido elétrico grave que fica na água, com estalos esparsos |

## Critérios de aceite

- [x] As seis Técnicas têm ícone, efeito e som, e a Faísca de Alga tem o projétil.
- [x] O Godot importa os 19 arquivos, e o jogo abre sem erros de script.
- [ ] O dono vê e ouve as seis numa luta.

## Desenho técnico

**Criar:** `art-source/skills/flora_volt_icons.jpg` (a imagem do dono), os seis ícones, efeitos e sons e o projétil, com os `.import`.

**Alterar:** seis linhas do `EFFECTS` e uma do `PROJECTILES` no `cut_effects.gd`; no `element_skills.py`, a peça `zap`, as seis funções e a tabela `SOUNDS`. Nenhum código do jogo muda.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- flora_volt_icons.jpg bicada_de_folha garra_de_espinho asa_semeadora faisca_de_alga corrente_viva mare_eletrica
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" bicada_de_folha garra_de_espinho asa_semeadora faisca_de_alga corrente_viva mare_eletrica
python -I art-source/sounds/element_skills.py bicada_de_folha garra_de_espinho asa_semeadora faisca_de_alga corrente_viva mare_eletrica
godot --headless --path client --import
```

Recortar o ícone de novo traz de volta o quadrado preto da Garra de Espinho: preencha-o outra vez, ou peça a imagem limpa ao dono.

## Resultado da verificação

Em 2026-11-19, sem janela:

- **Escolha dos efeitos:** folhas de contato do kit inteiro na 4ª e na 1ª linha e tiras com todos os quadros dos candidatos. As folhas já usadas pela Flora ficaram de fora.
- **Arquivos:** os 6 ícones com 256 × 256; os 6 efeitos, com 8 a 14 quadros; o projétil, com 14; os 6 sons, com a duração da tabela e pico de 0,7, e o volume médio (RMS) entre 0,12 e 0,25, na faixa dos de antes. Uma imagem com cada ícone ao lado de 8 quadros do efeito foi mandada ao dono.
- **Projeto:** o jogo sem janela abre sem erros de script.
- **Falta o dono:** os sons não foram ouvidos aqui. A linha do Volt é laranja e amarela, mais quente que o amarelo do Elemento (`#F5C518`); se ela parecer fogo na luta, dá para tingir o Volt pela cor dele, como o Vento e a Terra (`ELEMENT_TINTS`).
