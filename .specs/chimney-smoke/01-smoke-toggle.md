# 01. A casa sem fumaça

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [home-pack](../home-pack/) (a fumaça da chaminé) e [free-objects](../free-objects/) (o contrato das peças)

## Contexto

Toda casa com chaminé solta fumaça; o dono quer poder desligar em cada uma ([README](README.md#contexto)).

## Escopo

- A coluna `island_props.no_smoke` (`bool`, padrão `false`), na migração `20261231000000_prop_no_smoke`.
- O campo `no_smoke` nas peças do rascunho (`PUT /v1/editor/islands/:id/draft`), da leitura do editor e do mapa de Explorar numa ilha.
- O `MapProp.no_smoke` no jogo, o `HexMapView` sem a fumaça dessas peças e o botão na `ObjectBar` do editor.

## Requisitos

- **RF-01:** A peça do rascunho aceita `no_smoke` (verdadeiro ou falso, opcional). O servidor grava `true` na coluna e, ao ler, só manda `"no_smoke": true` nas peças que têm a marca; sem o campo, a peça solta fumaça.
- **RF-02:** O `HexMapView` não desenha a fumaça de uma peça com `no_smoke`, no jogo e no editor. As outras peças do mesmo tipo seguem com fumaça.
- **RF-03:** Na barra da peça escolhida (`ObjectBar`), um botão de ligar e desligar com o ícone de fumaça ("Fumaça da chaminé") aparece só quando o tipo dela tem fumaça (`HexMapView.PROP_SMOKE`). Apertado, ele mostra a fumaça ligada; soltar marca a peça com `no_smoke`, e apertar de novo tira a marca. A troca entra no desfazer ("Fumaça da peça").
- **RF-04:** O carimbo guarda e põe a marca junto com a peça, como a ação.

## Critérios de aceite

- [ ] No F2, escolher uma Casa grande mostra o botão da fumaça na barra; desligar tira a fumaça só dela, e Ctrl+Z volta.
- [ ] Depois de salvar e publicar, a casa sem fumaça fica sem ela em Explorar, e as outras seguem com fumaça.
- [ ] Uma peça sem chaminé (uma árvore, a Casinha de pedra) não mostra o botão.
- [x] Os testes do servidor (o rascunho com `no_smoke`) passam.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script.
