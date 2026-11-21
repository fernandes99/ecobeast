# veilmoth-line

Uma linha nova de duas formas, a mariposa gêmea: o **Veilmoth** (Arcano) e o **Gatemoth** (Arcano/Inseto), os primeiros Ecobeasts de Arcano. É Épica, só nasce à Noite e traz a Técnica **Teleporte**, que leva qualquer Ecobeast do campo (ele mesmo, um aliado ou um inimigo) para qualquer hexágono vazio do tabuleiro.

## Contexto

Em 2026-11-19, na [portal-altar](../portal-altar/), o dono escolheu as mariposas gêmeas como o Ecobeast que teleporta entre as ilhas: ela tem olhos-portal nas asas e só se teleporta para onde há outra do mesmo bando, então cada ilha com um altar guarda uma mariposa. O altar já é a peça 101; a espécie e a regra do teleporte entre as ilhas ficaram para depois.

Em 2026-11-21, o dono pediu "Vamos elaborar agora o ecobeast que será responsável por teleportar" e mandou a imagem da linha, gerada numa IA, com "bora criar". Ela fica em `art-source/veilmoth/line.webp` (1774×887, fundo branco), com as duas formas da esquerda para a direita, as duas olhando para a direita.

A imagem mostra:

- **Veilmoth:** uma mariposa pequena e redonda, de asas violeta com as bordas lilás e creme, um olho-portal em cada asa de cima (um redemoinho violeta escuro com o anel claro), a gola de pelo creme, a cabeça violeta com os olhos lilás brilhantes, as antenas de pluma lilás e as asas de baixo pendendo como duas caudas curtas.
- **Gatemoth:** uma mariposa grande e majestosa, de asas largas e recortadas com olhos-portal maiores e cheios de estrelas, as antenas de pluma douradas, uma máscara escura nos olhos, a juba creme com um broche de cristal violeta em moldura dourada, o corpo de penas violeta e três caudas longas de véu, duas delas com cristais violeta na ponta.

Junto com a arte, o dono pediu a Técnica: "vamos ter a habilidade de teleporte, é uma técnica bem rara, que pouquissimos ecobeast podem ter. em campo de batalha essa técnica vai ter um recurso novo, ele vai poder usar para teleportar para qualquer lugar do campo ele mesmo ou um aliado, com um coutdown de 3". Depois: "O teleporte vai poder também teleportar os inimigos para qualquer campo".

Claude leu o motor da luta: toda Técnica escolhe hoje um hexágono só (`target` da ação `skill`, em `server/src/domain/board/types.ts`), e o alvo é Inimigo, Si mesmo, Todos ou Meu time (`skill_targets`). O Teleporte pede duas escolhas, quem vai e para onde, então é regra nova no servidor e na tela da luta.

## Objetivos

1. As espécies 36 e 37, a raridade Épica, só à Noite, com os `front.png` e as folhas do mapa.
2. As primeiras Técnicas de Arcano.
3. O Teleporte: tocar num Ecobeast qualquer do campo e depois num hexágono vazio, com countdown de 3.

## Anti-objetivos

- O Veilmoth no Hub, na história ou de presente: o jogador só o tem capturando.
- Mudar as Técnicas e as regras que já existem.
- Outro Ecobeast aprendendo o Teleporte nesta iniciativa.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| A arte da imagem dele | "bora criar, vou te passar a arte" |
| A raridade Épica | "ele será épico"; "bem rara mas não é algo MEGA épico [...] de 0 a 100 [...] ela fica em ~10/12" |
| Capturável, só à Noite, nunca dada pela história | "sim, ela é capturável. Ela só nasce a noite, e o jogador não vai ganahr ela na história" |
| As mariposas dos altares não são do jogador | "Vão excistir elas nos altares mas o jogador não via poder pegar" |
| O Teleporte é raro, leva qualquer Ecobeast do campo para qualquer hexágono, com countdown 3 | As duas falas citadas no Contexto |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Veilmoth de Arcano (14), Gatemoth de Arcano/Inseto (14 e 15) | A proposta de 2026-11-19, que o dono não mudou |
| Rápida e frágil, com bom Ataque Especial: totais 330 e 520 | Um suporte que reposiciona o time e foge, e não um tanque |
| Peso 10 no Boreal e 5 na Colina (Veilmoth), o dobro na Clareira do Boreal | O "~10/12" do dono: cerca de um quinto de um comum, que tem de 40 a 60 |
| Evolui no nível 32, pelo gatilho de nível | O ritmo das linhas de duas formas incomuns e raras |
| Três fases: a linha, as Técnicas de Arcano sem regra nova e o Teleporte | O Teleporte é a parte grande e nova; as outras duas seguem o caminho das linhas de antes |
| O Teleporte é um efeito novo (`teleport`) com um alvo novo (`any`, "Qualquer Ecobeast") | O editor de Técnicas do F1 monta qualquer Técnica por alvo e efeitos; separar os dois deixa outro Ecobeast ganhar o Teleporte sem código |

## Fora do escopo

- A regra do teleporte entre as ilhas pelo altar e a mariposa do altar como NPC.
- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- O ícone, o efeito animado e o som das Técnicas novas (o Teleporte ganha só o sumir e aparecer da [fase 3](03-teleport.md)).
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-veilmoth-line](01-veilmoth-line.md) | As duas espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-arcane-skills](02-arcane-skills.md) | Três Técnicas de Arcano com as regras de hoje | concluída (falta o dono conferir no jogo) |
| 3 | [03-teleport](03-teleport.md) | O Teleporte: o alvo, o efeito, a ação com destino, a tela, a IA e o F1 | concluída (falta o dono conferir no jogo) |
