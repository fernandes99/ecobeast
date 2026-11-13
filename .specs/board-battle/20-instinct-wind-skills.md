# 20. Ícone, efeito e som de seis Técnicas de Instinto e de Vento

- **Status:** concluída (falta o dono ver e ouvir no editor)
- **Depende de:** [18](18-element-skill-effects.md) e [19](19-element-skill-sounds.md) (o recortador de efeitos e o gerador de sons)

## Contexto

Em 2026-11-13, o dono pediu o título, a descrição e o Elemento de seis Técnicas do catálogo, sem ícone, efeito nem som: Uivo, Patada e Olhar Manhoso (Instinto) e Lufada Cortante, Dança do Vento e Ciclone (Vento). Perguntou também qual é o hexadecimal do Vento (`#7CC9B8`, verde-água). Depois, mandou uma imagem com os seis ícones, em 3 colunas e 2 linhas, nessa ordem, e pediu: "Agora crie essas habilidades".

As seis já existem no catálogo, com os dados e a descrição. Faltam os arquivos: ícone, efeito e som. Os ícones de Vento são verde-água, e a linha do Vento no kit de efeitos (a 6ª, [18](18-element-skill-effects.md), RF-01) é cinza. Por isso, a cinza passa a ser tingida com a cor do Vento.

## Escopo

- Os seis ícones, recortados da imagem do dono.
- Os seis efeitos, do kit, e os seis sons, por síntese.
- O tingimento da linha do Vento com a cor dele.

## Fora do escopo

- Mudar os dados das seis Técnicas no catálogo.
- Tingir outros Elementos: o Metal continua na 6ª linha, cinza, como ela vem no kit.

## Requisitos

- **RF-01:** Os ícones ficam em `res://assets/skills/<slug>.png`, com 256 × 256 e sem transparência, recortados de `art-source/skills/instinto_vento_icons.jpg` pelo `cut_icons.gd`. Esse script passa a aceitar o nome da imagem e os slugs na ordem de leitura. Sem argumentos, ele faz o mesmo de antes.
- **RF-02:** No `cut_effects.gd`, um Elemento em `ELEMENT_TINTS` tem a linha dele multiplicada pela cor dele no catálogo. Hoje, só o Vento, com `#7CC9B8`: a 6ª linha, cinza e branca, vira verde-água, com a mesma luz e sombra. Os quatro de antes e os 22 da [18](18-element-skill-effects.md) não mudam.
- **RF-03:** O efeito de cada Técnica, escolhido por Claude pela forma e pelo ícone (_a revisar_):

  | Técnica | Elemento | Alvo | Folha | Forma |
  | --- | --- | --- | --- | --- |
  | Uivo | Instinto | si mesmo | 12/586 | um anel que cresce e solta pontas, como o uivo se espalhando |
  | Patada | Instinto | inimigo | 2/71 | um estouro em estrela que se parte em lascas, como no ícone |
  | Olhar Manhoso | Instinto | inimigo | 15/703 | um losango de escudo que se forma e se parte em pedaços |
  | Lufada Cortante | Vento | inimigo | 9/438 | uma lâmina de vento em meia-lua |
  | Dança do Vento | Vento | si mesmo | 12/567 | um vento que gira em volta do corpo |
  | Ciclone | Vento | inimigo | 1/03 | um redemoinho que se fecha e se desfaz |

  Instinto é a 5ª linha, marrom; Vento é a 6ª, tingida (RF-02). As seis têm alcance 1, então nenhuma tem projétil. O Uivo e a Dança do Vento tocam o efeito sobre quem as usou ([18](18-element-skill-effects.md), RF-05).

- **RF-04:** O som de cada Técnica, por síntese, sem gravação de terceiros, no `element_skills.py` (_a revisar_):

  | Técnica | Duração | Som |
  | --- | --- | --- |
  | Uivo | 0,9 s | um uivo de lobo: uma voz que sobe, segura com vibrato e cai no fim |
  | Patada | 0,45 s | o zunido da pata vindo, um baque pesado e um estalo de impacto |
  | Olhar Manhoso | 0,9 s | um brilho agudo, um tom grave e sinuoso que desce e o escudo trincando em cacos |
  | Lufada Cortante | 0,45 s | uma rajada que corta do agudo para o médio, com um assobio de lâmina |
  | Dança do Vento | 0,7 s | um vento que gira, com notas leves que sobem |
  | Ciclone | 0,7 s | um redemoinho que ronca e gira rápido, com um assobio que sobe |

## Critérios de aceite

- [x] As seis Técnicas têm ícone, efeito e som.
- [x] Numa luta sem janela, cada uma toca o efeito e o som juntos, no Ecobeast certo.
- [ ] O dono vê e ouve as seis numa luta.

## Desenho técnico

**Criar:** `art-source/skills/instinto_vento_icons.jpg` (a imagem do dono), os seis ícones, efeitos e sons, com os `.import`.

**Alterar:**
- `art-source/skills/cut_icons.gd`: os argumentos (RF-01).
- `res://assets/effects/skills/cut_effects.gd`: `ELEMENT_TINTS` e as seis linhas do `EFFECTS`.
- `art-source/sounds/element_skills.py`: as seis funções e a tabela `SOUNDS`.

```bash
godot --headless --path client -s ../art-source/skills/cut_icons.gd -- instinto_vento_icons.jpg uivo patada olhar_manhoso lufada_cortante danca_do_vento ciclone
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" uivo patada olhar_manhoso lufada_cortante danca_do_vento ciclone
python -I art-source/sounds/element_skills.py uivo patada olhar_manhoso lufada_cortante danca_do_vento ciclone
```

## Verificação

- Uma imagem com os ícones e os quadros dos efeitos vai ao dono.
- O resumo do volume de cada som confere a forma e que nenhum estoura.
- Um teste sem janela, numa luta montada à mão, usa as seis e confere que o efeito aparece uma vez, no Ecobeast certo, com o som tocando.
- O jogo sem janela abre sem erros de script.
- Manual, com F5: o dono vê e ouve as seis numa luta.

## Tarefas

- [x] Spec.
- [x] Os ícones, os efeitos e os sons.
- [x] A imagem, o resumo do volume e o teste sem janela.
- [ ] O dono ver e ouvir com F5.

## Resultado da verificação

Em 2026-11-13, sem janela:

- **Ícones:** o `cut_icons.gd` achou os 6 quadros pelas faixas pretas (3 colunas e 2 linhas) e gravou os 6 ícones com 256 × 256.
- **Efeitos:** o `cut_effects.gd` gravou os 6, com 10 a 22 quadros. Os de Vento saíram verde-água. Uma imagem com cada ícone ao lado de 6 quadros do efeito foi mandada ao dono.
- **Sons:** o resumo em pedaços de 0,05 s mostrou o ataque e o fim esperados, sem estourar. O Uivo, um tom longo, saía bem mais alto que os outros e ganhou menos saturação. A Dança do Vento e o Ciclone saíam baixos e ganharam mais.
- **Luta:** uma cena temporária (já apagada) usou as seis numa luta montada à mão. Cada uma mostrou o efeito uma vez, com o som dela tocando no mesmo quadro. O Uivo e a Dança do Vento mostraram o efeito sobre quem os usou, e as outras sobre o alvo.
- **Projeto:** importa sem erros, e o jogo sem janela abre sem erros de script.
- **Falta o dono:** os sons não foram ouvidos aqui. O dono vê e ouve as seis numa luta com F5.
