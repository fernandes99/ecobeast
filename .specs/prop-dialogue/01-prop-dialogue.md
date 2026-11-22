# 01. A fala da peça

- **Status:** concluída (falta o dono conferir no F2 e no jogo)
- **Depende de:** [free-objects](../free-objects/) (a ação da peça), [island-npcs](../island-npcs/) (a conversa) e [dialogue-voices](../dialogue-voices/) (a voz da narração)

## Contexto

A peça só abre tela ou sala; o dono quer que uma placa fale ([README](README.md#contexto)).

## Escopo

- A coluna `island_props.dialogue` (`text`, padrão `''`, `CHECK char_length <= 2000`), na migração `20270204000000_prop_dialogue`.
- O campo `dialogue` nas peças do rascunho (`PUT /v1/editor/islands/:id/draft`), da leitura do editor e do mapa de Explorar numa ilha.
- A caixa Fala no `ObjectPanel` do F2, o carimbo e a conversa da peça na `ExplorationScreen`.

## Requisitos

- **RF-01:** A peça do rascunho aceita `dialogue` (texto, opcional). O servidor grava o texto e, ao ler, só manda `dialogue` nas peças com texto. Mais de 2.000 caracteres (em code points) é recusado com "A fala da peça N passa de 2.000 caracteres.".
- **RF-02:** A fala entra no hash do conteúdo da ilha só quando há texto: uma ilha sem fala tem o hash de antes.
- **RF-03:** No F2, com uma peça escolhida, a caixa "Fala (opcional) · cada parágrafo é uma fala" aparece embaixo da Sala. Digitar grava na peça; a troca entra no desfazer ("Trocar a fala da peça") meio segundo depois da última letra, ao escolher outra peça ou ao sair da caixa. Apagar todo o texto tira o campo.
- **RF-04:** O carimbo guarda e põe a fala junto com a peça.
- **RF-05:** Em Explorar, a peça com fala é tocável como a de ação: o Domador anda até encostar e a conversa começa. A caixa de fala mostra cada parágrafo sem nome, com a voz da narração, e trava o mapa como a conversa do NPC. Depois da última fala, a sala abre ou a ação roda, se a peça tiver.
- **RF-06:** Uma peça sem fala, ação nem sala segue deixando o toque passar para o chão.

## Critérios de aceite

- [ ] No F2, escolher a Placa de direção mostra a caixa Fala; escrever, salvar e reabrir a ilha traz o texto de volta, e Ctrl+Z desfaz a fala.
- [ ] Em Explorar, tocar na placa com duas falas mostra as duas, uma por toque, e o mapa volta a andar depois.
- [ ] Uma peça com fala e a ação Loja mostra a fala e depois abre a Loja.
- [x] Os testes do servidor (o rascunho com `dialogue`, o limite e a leitura) passam.
- [x] `godot --headless --path client --quit-after 240` roda sem erro de script.

## Tarefas

- [x] Migração, `schema.prisma`, `DraftProp.dialogue`, validação, hash, DTOs, gravação e leitura; testes de unidade e e2e.
- [x] `MapProp.dialogue` e `lines()`, a caixa no `ObjectPanel`, o carimbo e a conversa na `ExplorationScreen`.
- [x] Conferência sem janela; status, README e roadmap.
