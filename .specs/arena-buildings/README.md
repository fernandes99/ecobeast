# arena-buildings

Os prédios da Arena entram nas ilhas como peças soltas, montados pelos tiles do pacote **Fantasy Dreamland Reborn** (ElvGames): a Arena fortaleza, dos tiles do Castle, e a Arena coliseu, do anel octogonal do Dungeon, aberta ou fechada.

## Contexto

Em 2026-11-22, o dono pediu: "Vamos criar a construção da primeira arena, consegue criar o visual dela? Faça com base nos tilesets desse pacote", apontando a pasta `Tilesets/Dungeon/Sprites` do pacote.

O Dungeon (`FDR_Dungeon.png`, 512×416, tiles de 16×16) é feito para o lado de dentro de masmorras: paredes de tijolo com a borda de pedra clara, um anel de parede octogonal visto por dentro, portas, janelas com grade, colunas, estandartes vermelhos e pretos, baús, pedestais com orbes e tochas animadas (`FDR_Dungeon_Animations.png`). Ele não tem telhado, torre nem portão grande. O tileset **Castle** do mesmo pacote tem: a muralha com ameias (`FDR_Castle_Tiles.png`), a escadaria, os mesmos estandartes, a grade levadiça em 6 quadros (`FDR_Castle_Door05.png`) e o braseiro aceso em 8 quadros (`FDR_Castle_Torches.png`).

Claude mostrou duas prévias, a fortaleza e o coliseu aberto, e o dono respondeu: "Coloca os dois. No coliseu eu gostaria que tivesse a versão fechada dele". A versão fechada é o mesmo octógono coberto por um terraço de lajes de pedra, aprovada pelo dono pela prévia ("Sim, pode seguir"). As prévias ficam em `art-source/arena/`.

Hoje não existe prédio da Arena: o de antes (tipo 23, `arena_building`) saiu na [prop-cleanup](../prop-cleanup/), e o id dele não volta.

## Objetivos

1. A Arena fortaleza e a Arena coliseu são peças soltas da ferramenta Peças, na categoria Prédios, espelháveis, com o bloqueio no pé.
2. O coliseu tem 2 variantes: 1, aberto, com a areia, a arquibancada e os estandartes por dentro; 2, fechado, coberto por lajes de pedra.
3. Os braseiros da frente queimam, com os 8 quadros do braseiro do pacote, e acendem à noite.
4. A arte sai de um script que recorta e monta os tiles do pacote.

## Anti-objetivos

- As peças de antes não mudam.
- Nenhuma regra nova: a Arena continua sem tela e sem sala; o editor dá a ação Arena à peça pela lista Ação, como a qualquer peça.
- Nada no mapa sorteado.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| A fortaleza e o coliseu entram, e o coliseu tem o aberto e o fechado | "Coloca os dois. No coliseu eu gostaria que tivesse a versão fechada dele" |
| O fechado é o octógono coberto por lajes, com a frente mais alta | Aprovado pela prévia: "Sim, pode seguir" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A fortaleza é o tipo de peça 190 (`arena_fortress`, "Arena fortaleza") e o coliseu o 191 (`arena_coliseum`, "Arena coliseu"), na categoria 2 (Prédios) | O 189 (Rochedo de cinza) é o último tipo |
| O aberto e o fechado são variantes do mesmo tipo (1 e 2), não dois tipos | São o mesmo prédio, como o altar com e sem a mariposa |
| Sem as 8 cores das casas | São prédios de pedra, sem telhado para trocar de cor; o dono pode pedir depois |
| A fortaleza junta os tiles do Castle e o coliseu os do Dungeon, com a grade levadiça, o braseiro e os degraus do Castle | O Dungeon não tem portão grande nem braseiro de chão; os dois tilesets usam a mesma pedra e o mesmo tijolo |
| A parede de fora das diagonais da frente do coliseu é o tijolo da parede norte do Dungeon, coluna por coluna, descendo 1 px por coluna | O Dungeon só desenha o anel por dentro; a parede vista de fora não existe no pacote |
| Os braseiros ficam acesos de dia também, e só a luz deles acende à noite | São fogo; um braseiro apagado de dia pareceria quebrado |
| A arte fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | É a arte do pacote, como na [village-pack](../village-pack/) |
| A carga inicial (`seed-data`) não muda; os tipos entram só pela migração | Como o Altar-portal e os picos de basalto |

## Fora do escopo

- A sala da Arena, os Mestres e os emblemas: são da [auralis](../auralis/) (fase 05-arenas).
- A grade levadiça abrindo quando o Domador entra.
- O coliseu ou a fortaleza no mapa sorteado.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-arena-props](01-arena-props.md) | A Arena fortaleza (190) e a Arena coliseu (191, aberta e fechada), com os braseiros animados, as luzes e o bloqueio no pé | concluída (falta o dono conferir) |
