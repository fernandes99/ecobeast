# seedlet-line

O inicial de Flora ganha a arte nova que o dono mandou e outros nomes: o Browt, o Eagrow e o Sowingle viram o **Seedlet**, o **Grovequill** e o **Arbornix**, nos mesmos ids, com os `front.png` e as folhas `idle` e `walk` do mapa refeitos.

## Contexto

Em 2026-11-19, o dono mandou a imagem da linha nova (`art-source/seedlet/line.webp`, 1536×1024, com fundo transparente) e pediu: "Vamos alterar os ecobeast iniciais browt, eagrow e sowingle. [...] recrie as animações e também vamos dar outro nome". A imagem mostra:

- um filhote de quatro patas, com crista de folhas, olhos grandes e a ponta da cauda em folha;
- uma ave-dinossauro esguia de duas pernas, com bico, pescoço longo, garras escuras e cauda longa de folhas;
- uma fênix de folhas, de asas abertas, com chifres dourados, losangos brilhando nas asas e na cauda e folhas soltas em volta.

Claude sugeriu três trios de nomes, e o dono escolheu o terceiro, com os Elementos de hoje.

## Objetivos

1. Seedlet, Grovequill e Arbornix nos ids 7, 8 e 9, com slug, nome e descrição novos.
2. Os `front.png` novos, recortados da imagem, nas pastas com os slugs novos.
3. As folhas `idle.png` e `walk.png` do mapa das três formas, desenhadas de novo pela skill `creature-sprites`.

## Anti-objetivos

- Mudar as regras da linha: Elementos, atributos, Traços, learnsets, partes do dia, biomas, evoluções e captura ficam como na [browt-line](../browt-line/README.md).
- Mexer nos Ecobeasts já capturados: um Browt vira um Seedlet só pelo nome e pela arte.

## Decisões

Do dono, em 2026-11-19:

| Decisão | Motivo |
| --- | --- |
| Os nomes Seedlet, Grovequill e Arbornix | Escolha entre as sugestões de Claude: *seed* + *-let*, *grove* + *quill* (pena) e *arbor* + *phoenix* |
| Flora no Seedlet, Flora/Vento no Grovequill e no Arbornix | Pedido do dono, igual a hoje |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A altura do Seedlet passa de 0,3 m para 0,4 m (e o peso de 2,6 kg para 3,2 kg), e o Grovequill fica com 14 kg | Com 4 pixels no mapa, as quatro patas e a crista do filhote não cabem; com 6, cabem. O Grovequill é mais esguio que a ave de antes |
| As partes do dia, as Técnicas e os atributos não mudam | O dono só pediu a arte e os nomes. A Rasante e a Asa Semeadora, golpes de voo, continuam com o Grovequill, que é Flora/Vento como antes |
| A mudança vai numa migração (`20270104000000_seedlet_line`) | É o jeito das fases de hoje; a [browt-line](../browt-line/README.md) gravou o SQL sem arquivo |
| `server/prisma/seed-data/` não muda | É só a foto da carga inicial, como na browt-line |
| A imagem antiga (`art-source/browt/line.webp`) fica | É a fonte da browt-line, e nada do jogo a lê |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Rever o equilíbrio ou as Técnicas da linha.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-seedlet-line](01-seedlet-line.md) | Nomes, slugs, descrições, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
