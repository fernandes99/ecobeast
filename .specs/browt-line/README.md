# browt-line

A linha inicial de Flora refeita: o Elu, o Eluvin e o Eluvara (a lebre com broto) viram o **Browt**, o **Eagrow** e o **Sowingle**, uma ave de penas-folha que ganha o Vento a partir da segunda forma. A linha passa a lutar com garras e mergulhos, e quatro Técnicas novas e uma marca no chão, o Espinheiro, entram no catálogo.

## Contexto

Em 2026-11-16, o dono mandou a imagem da linha nova (`art-source/browt/line.webp`, com fundo transparente):

- uma corujinha amarela com sobrancelhas e asas de folha;
- uma ave de rapina esguia, com crista e cauda longa de folhas;
- uma ave grande, de asas abertas com espirais e cauda de penas-folha.

Ele pediu para reformular o inicial Elu inteiro, com os nomes **Browt**, **Eagrow** e **Sowingle**, Flora/Vento a partir da segunda forma, e sem apagar as Técnicas da linha antiga, que podem servir para outros Ecobeasts. Quando Claude perguntou como a linha nova deveria lutar, ele deixou a proposta com Claude.

Hoje a linha é Flora, Flora e Flora/Vento, puxa para Ataque Especial e tem sono e cura. Os ids 7, 8 e 9 estão em `starter_options` e no estado dos jogadores que escolheram o Elu.

## Objetivos

1. Browt, Eagrow e Sowingle nos ids 7, 8 e 9, com nome, slug, descrição, Elementos, atributos, partes do dia e learnsets novos.
2. Quatro Técnicas novas, todas físicas, e a marca Espinheiro, sem regra nova no motor da luta.
3. Os `front.png` novos e as pastas de arte com os slugs novos.
4. As Técnicas antigas da linha continuam no catálogo.

## Anti-objetivos

- Ids novos para a linha: os iniciais já escolhidos ficariam apontando para uma espécie que não é mais inicial.
- Mexer no que os Ecobeasts já capturados sabem: eles mantêm as Técnicas, o nível e os Genes.
- Repetir o papel da Galecrest, que já é a ave de Vento especial e de suporte.

## Decisões

Do dono, em 2026-11-16:

| Decisão | Motivo |
| --- | --- |
| Os nomes Browt, Eagrow e Sowingle | Pedido do dono |
| Flora no Browt, Flora/Vento no Eagrow e no Sowingle | Pedido do dono |
| Não apagar as Técnicas da linha antiga | Podem servir para outros Ecobeasts |
| O papel na luta fica com Claude | Pedido do dono |

Os nomes juntam palavras (*eagle* + *grow*, *sow* + *wing*). A regra do `CLAUDE.md` pedia palavras inventadas nos 3 iniciais e foi ajustada: agora só o Ruvo e o Nilu seguem essa regra.

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os mesmos ids (7, 8 e 9), evoluções (5 e 6, nos níveis 16 e 36), raridade, captura, XP, Traços e biomas | O jogador que tem um Elu passa a ter um Browt sem migrar nada. Os testes que contam os biomas continuam valendo |
| Uma ave de rapina mista, que puxa para Ataque e Velocidade | A Galecrest já é a ave especial. As Técnicas especiais de Flora e Vento que já existem continuam úteis, porque o Ataque Especial não fica baixo |
| Os totais de atributos iguais aos da linha antiga (318, 420 e 532) | O equilíbrio com o Ruvo e o Nilu não muda |
| O Browt nasce no Final de tarde e à Noite. O Eagrow e o Sowingle, de Manhã, de Tarde e no Final de tarde | O filhote é uma corujinha, e as formas adultas caçam de dia |
| Quatro Técnicas novas: Bicada de Folha, Garra de Espinho, Rasante e Asa Semeadora | A linha física precisava de golpes físicos de Flora e de Vento, e o catálogo só tem o Chicote de Raiz |
| A marca Espinheiro tira 6% do HP máximo de quem termina a vez nela, como o Chão em chamas | O Sowingle "semeia". A regra de dano das marcas já existe, então nada muda no motor |
| Saem da linha a Patada, o Chicote de Raiz, os Esporos Sonolentos e a Dança do Vento | Ficam no catálogo, sem quem aprenda, como o dono pediu |
| As folhas `idle`, `walk` e o `board.png` da lebre são apagados | Mostrariam a lebre. As folhas `idle` e `walk` novas foram feitas depois, pela skill `creature-sprites`. Sem `board.png`, o tabuleiro mostra o `front.png` reduzido |
| `server/prisma/seed-data/` não muda | É só a foto da carga inicial, como na [puffcoo-line/03](../puffcoo-line/03-puffcoo-line.md) |

## Fora do escopo

- O `board.png` e as folhas da luta (`battle/`) das três formas e o som `call.wav`. As folhas `idle.png` e `walk.png` do mapa foram feitas depois da fase 1, pela skill `creature-sprites`, nas alturas do catálogo: 4, 15 e 26 pixels.
- O ícone, o efeito e o som das Técnicas novas e o desenho do Espinheiro no tabuleiro. Até lá, a marca é o hexágono tingido com a cor dela.
- Ensinar as Técnicas que saíram da linha a outras espécies.

## Pré-requisitos

- [puffcoo-line](../puffcoo-line/): o Vento a Favor e as marcas pela linha reta.
- [day-phase-spawns](../day-phase-spawns/): `species_day_phases`.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-browt-line](01-browt-line.md) | Dados e arte: as três espécies, as 4 Técnicas, o Espinheiro, os learnsets, as partes do dia e os `front.png` | concluída (falta o dono conferir no jogo) |
