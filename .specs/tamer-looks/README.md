# tamer-looks

Mais opções de aparência para o Domador e os NPCs pessoas, no guarda-roupa provisório gerado pelo `make_wardrobe.gd`.

## Contexto

Em 2026-11-24, o dono pediu: "Vamos agora melhorar as aparências do personagem. Vamos começar pelo rosto. Hoje temos 2 rostos, crie mais 3." O rosto é uma peça do lugar `face` (`appearance_parts`), sem paleta, desenhada por código sobre o template da Eris Esra, no adulto e na criança.

## Objetivos

1. Mais rostos para escolher na tela Aparência e no botão Aparência da ferramenta NPC do F2.
2. As outras partes da aparência, uma de cada vez, nas próximas fases.

## Anti-objetivos

- O jeito de montar o Domador não muda: corpo, peças em camadas e as cores-chave trocadas pela paleta.
- As peças de antes não mudam, pixel a pixel.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A partir da fase 2, as peças novas só têm a folha de adulto, e a criança não as mostra | Pedido do dono |
| Uma peça ou um corpo editado à mão entra no `assets/tamer/hand_drawn.json`, que o `make_wardrobe.gd` lê e deixa de gravar (a fase 4 começou com a lista `HAND_DRAWN` no script; a fase 5 a trocou pelo arquivo, que o F6 escreve) | O script gera todas as peças de uma vez e apagaria a edição |
| A Saia longa é só do corpo Feminino, como a Saia | Segue a regra da peça que já existe; o dono a libera pelo painel se quiser |
| Os rostos novos se chamam "Rosto 3" a "Rosto 7", como os de antes | A tela Aparência mostra a miniatura, e os nomes seguem os que já existem |
| Os 3 primeiros rostos são os olhos brilhantes, as sardas e os olhos semicerrados; os 2 seguintes, os olhos fechados de alegria (arco e ^) da imagem do dono | Cada um muda o rosto de um jeito que se lê em 25 pixels de altura, e também na criança |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-faces](01-faces.md) | Os rostos 3 a 7 | concluída (falta o dono conferir na tela Aparência) |
| 2 | [02-bottoms](02-bottoms.md) | A Saia longa, a Calça capri e a Calça boca de sino | concluída; as 3 saíram na fase 6 |
| 3 | [03-shoes](03-shoes.md) | O Tênis e a Bota sem o pixel faltando, a Galocha e o Sapato | concluída (falta aplicar a migration e o dono conferir) |
| 4 | [04-pants-run](04-pants-run.md) | A Calça certa na corrida e a lista `HAND_DRAWN` das peças editadas à mão | concluída (falta o dono conferir no jogo) |
| 5 | [05-wardrobe-editor](05-wardrobe-editor.md) | O editor de roupas no F6, pixel a pixel, com o salvar por peça ([plano](05-wardrobe-editor-plan.md)) | concluída (falta o dono conferir no F6) |
| 6 | [06-fewer-parts](06-fewer-parts.md) | Saem o cabelo Comprido, a Jaqueta, a Regata, a Saia longa, a Calça capri e a Calça boca de sino | concluída (falta aplicar a migration e o dono conferir) |
