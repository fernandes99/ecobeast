# 28. Os projéteis das Técnicas que lançam algo

- **Status:** concluída (falta o dono ver no jogo)
- **Depende de:** [15](15-projectile-effects.md) (o voo pelo arquivo) e [27](27-flora-volt-skills.md)

## Contexto

Em 2026-11-19, o dono pediu: "reveja todas as técnicas, e aquelas que precisam de projetil, você coloca. Veja a descrição e decida se deve ter ou não." Até aqui, 4 das 65 Técnicas tinham projétil: a Faísca Rápida, a Chama Espiral, a Pena Afiada e a Faísca de Alga.

## Escopo

- O projétil das Técnicas cuja descrição diz que algo sai de quem ataca e vai até o alvo.

## Fora do escopo

- Código novo: o voo da [15](15-projectile-effects.md) já vale para qualquer Técnica com o arquivo `<slug>_projectile.png`.
- As Técnicas que ainda não têm efeito (Tempestade de Algas, Desabamento e Abalo Profundo): nenhuma delas lança algo.

## Requisitos

- **RF-01:** A regra de Claude (_a revisar_): tem projétil a Técnica de dano cuja descrição **dispara, lança ou arremessa** algo no alvo. Não tem:
  - as de contato, em que o corpo de quem ataca é o golpe (garras, mordidas, bicadas, patadas e o Rasante);
  - as que acontecem em volta do alvo ou nele (Ciclone, Tempestade de Pétalas, Inverno Mudo, Torrente, Maremoto, as explosões e o Eco Mental);
  - as que cobrem uma fileira inteira e deixam marca no chão, cujo efeito já aparece em cada hexágono (Vendaval, Asa Semeadora, Nuvem de Penas, Maré Elétrica e Corrente Viva);
  - as de suporte e de estado (rugidos, olhares, fumaça, espuma, esporos e as que cuidam de si ou de um aliado);
  - a Seiva Vital, em que a energia vai do alvo para quem ataca.
- **RF-02:** Ganham projétil sete Técnicas, todas recortadas da linha do Elemento delas ([18](18-element-skill-effects.md)), com a tinta do Vento e da Terra:

  | Técnica | Alcance | Descrição (o que voa) | Folha |
  | --- | --- | --- | --- |
  | Jato de Maré | 1 | "Dispara um jato de água" | 12/579 |
  | Folha Navalha | 1 | "Lança folhas afiadas" | 12/579 |
  | Lufada Cortante | 1 | "Dispara uma rajada de vento" | 12/579 |
  | Floco Cortante | 1 | "Lança um floco afiado" | 12/579 |
  | Lança de Cristal | 1 | "Dispara uma lança de gelo" | 12/579 |
  | Arremesso de Torrão | 1 | "Arremessa um torrão de terra" | 12/578 |
  | Rajada de Penas | 6 | "Lança de 2 a 5 penas seguidas, de longe" | 12/579 |

- **RF-03:** O kit só tem duas folhas que apontam para a direita, como o voo pede ([15](15-projectile-effects.md), RF-04): o risco em loop da 579, o de quase todas, e o bolo que cresce e se alonga da 578, o da Chama Espiral, que aqui fica só para o Arremesso de Torrão, porque parece um torrão voando. O que distingue cada uma é a cor do Elemento e o impacto no alvo.
- **RF-04:** Com alcance 1, o voo é de um hexágono, uns 0,09 s: um lampejo que liga quem lança ao alvo. Na Rajada de Penas, o projétil voa uma vez, e cada pena que acerta toca o impacto.

## Critérios de aceite

- [x] As sete Técnicas têm o `<slug>_projectile.png`, com o `.import`, e os efeitos de antes não mudaram.
- [x] O jogo sem janela abre sem erros de script.
- [ ] Na luta, o projétil de cada uma voa até o alvo antes do impacto.

## Desenho técnico

**Alterar:** sete linhas do `PROJECTILES` no `cut_effects.gd`.

```bash
godot --headless --path client -s res://assets/effects/skills/cut_effects.gd -- "<pasta Free do kit>" jato_de_mare folha_navalha lufada_cortante floco_cortante rajada_de_penas lanca_de_cristal arremesso_de_torrao
godot --headless --path client --import
```

## Resultado da verificação

Em 2026-11-19, sem janela: os sete projéteis saíram com 14 quadros (a 579) e 11 (a 578); o recorte regravou os efeitos das sete Técnicas com os mesmos bytes (o git não os mostra mudados); uma imagem com 6 quadros de cada um dos 11 projéteis foi mandada ao dono; o jogo abre sem erros de script. O voo não foi visto com janela.
