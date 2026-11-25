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
| A Saia longa é só do corpo Feminino, como a Saia | Segue a regra da peça que já existe; o dono a libera pelo painel se quiser |
| Os rostos novos se chamam "Rosto 3" a "Rosto 7", como os de antes | A tela Aparência mostra a miniatura, e os nomes seguem os que já existem |
| Os 3 primeiros rostos são os olhos brilhantes, as sardas e os olhos semicerrados; os 2 seguintes, os olhos fechados de alegria (arco e ^) da imagem do dono | Cada um muda o rosto de um jeito que se lê em 25 pixels de altura, e também na criança |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-faces](01-faces.md) | Os rostos 3 a 7 | concluída (falta o dono conferir na tela Aparência) |
| 2 | [02-bottoms](02-bottoms.md) | A Saia longa, a Calça capri e a Calça boca de sino | concluída (falta o dono conferir na tela Aparência) |
