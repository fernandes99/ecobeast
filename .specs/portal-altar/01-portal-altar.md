# 01. O altar-portal

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-props](../free-props/) (as peças soltas) e [day-night](../day-night/03-night-lights.md) (as luzes)

## Contexto

O objeto do teleporte, com e sem o Veilmoth ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_portal_altar.py` e a arte `client/assets/props/portal_altar/1.png` e `2.png`.
- O tipo de peça 101, com o bloqueio e as luzes, na migração `20270108000000_portal_altar`.
- A paleta Arcano no guia de estilo.

## Requisitos

- **RF-01:** `python -I make_portal_altar.py`, de dentro de `client/assets/props`, grava `portal_altar/1.png` e `2.png`, de 62×74, com o pé no meio da borda de baixo:
  - a sombra no chão, oval, preta a 18%;
  - a base redonda de pedra cinza, com a face de cima, a lateral com juntas a cada 6 px, o degrau da frente e o anel arcano gravado na face de cima;
  - dois pilares de 6 px, com juntas, musgo e uma gota violeta, e o arco sobre eles, com a pedra-chave de cristal arcano;
  - o pedestal no meio, com a bacia;
  - o contorno de 1 px da pedra, e o do cristal e da mariposa no tom de contorno do Arcano.
- **RF-02:** As variantes:
  - **1:** o Veilmoth parado sobre a bacia acesa, com os fiapos do portal no vão do arco em violeta e ciano;
  - **2:** a bacia apagada e poucos fiapos, no tom escuro do Arcano.
- **RF-03:** As cores são da Pedra cinza, da Folhagem de canteiro, do Reboco creme (o pelo da mariposa) e da paleta nova **Arcano**: `#d4ccff` claro, `#a99bff` base, `#6c5ce7` escuro e `#3b2c92` contorno, com o brilho ciano `#7fe8ff`.
- **RF-04:** O tipo de peça 101 é `portal_altar`, "Altar-portal", com 2 variantes. O bloqueio padrão (variante 0) é o hexágono fechado em volta da base: (−29, −12), (−21, −4), (20, −4), (28, −12), (20, −19) e (−21, −19).
- **RF-05:** As luzes da noite (`prop_type_lights`), postas à mão:

  | Variante | x | y | Raio | Cor | O quê |
  | --- | --- | --- | --- | --- | --- |
  | 1 | −1 | −69 | 10 | `a99bff` | a pedra-chave |
  | 1 | −1 | −39 | 20 | `7fe8ff` | o portal e a mariposa |
  | 2 | −1 | −69 | 7 | `a99bff` | a pedra-chave, mais fraca |

## Critérios de aceite

- [x] `GET /v1/catalog` traz o tipo 101, o bloqueio e as 3 luzes.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [ ] A ferramenta Peças do F2 mostra o Altar-portal, com as 2 variantes pelas teclas ← →, espelhado ou não.
- [ ] O Domador para na base do altar, e, com a ação Viagem dada pelo editor, tocar no altar abre a tela Viagem.
- [ ] À noite, a pedra-chave e o portal acendem.

## Verificação

```bash
cd client/assets/props && python -I make_portal_altar.py
cd server && npx prisma migrate deploy
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```
