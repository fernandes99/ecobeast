# biome-zones

Cada bioma ganha zonas, manchas com um caráter próprio, como um bosque fechado, um arbustal ou uma clareira quase sem mato. A zona muda as plantas sorteadas no hexágono e, no mapa sorteado, quais Ecobeasts nascem nele.

## Contexto

Em 2026-11-19, o dono pediu: "Nos biomas gostaria de criar variantes de cada bioma, além disso gostaria de colocar zonas de cada bioma, tipo uma zona só de pinheiros, outra zona só de arbustos, uma zona limpa que vai ter no maximo alguns matos. Essas zonas vão influenciar até mesmo nos tipos de ecobeasts que podem nascer nelas". Depois, disse: "Vamos deixar as variantes para depois, vamos focar apenas nas zonas."

Como funciona hoje:

- **O bioma:** cada hexágono tem um só bioma (`biomes`, ids 1 a 11).
- **As plantas:** saem de uma receita fixa por bioma (`HexDecorations.RECIPES`), sorteada no cliente pela seed e pelo hexágono. A mesma receita vale no mapa sorteado, nas ilhas e no tabuleiro da luta.
- **Quem nasce no mapa sorteado:** depende só do bioma, pela taxa de `species_biomes` (`rollSpawns`, em `server/src/domain/exploration/spawns.ts`).
- **Quem nasce nas ilhas:** depende das áreas pintadas no F2, cada uma com a sua lista de Ecobeasts (`rollAreaSpawns`).

## Objetivos

1. As 13 zonas da tabela abaixo, cada uma com a sua receita de plantas, mais uma zona Comum por bioma, com a receita de hoje.
2. O mapa sorteado gera as zonas em manchas dentro de cada bioma, e elas mudam as plantas e quem nasce.
3. Nas ilhas, o dono pinta as zonas no F2 pela ferramenta Zona. Elas mudam as plantas, mas quem nasce continua sendo decidido pelas áreas.
4. Uma tabela de exceções, editável pelo painel do Supabase, muda a taxa de um Ecobeast numa zona.

## Anti-objetivos

- O terreno de uma seed mudar: o bioma, a altura, a água e as pontes continuam iguais.
- Um hexágono que o dono não pintou numa ilha mudar de cara.
- Um Ecobeast sumir do mapa sorteado sem o dono ter posto 0 para ele numa zona.
- A zona mudar quem nasce nas áreas das ilhas.

## Decisões

Do dono, em 2026-11-19:

| Decisão | Motivo |
| --- | --- |
| Só as zonas agora; as variantes dos biomas ficam para depois | "Vamos deixar as variantes para depois, vamos focar apenas nas zonas." |
| As zonas valem no mapa sorteado e nas ilhas; nas ilhas, quem nasce continua pelas áreas | Escolheu "Nos dois, áreas mandam" |
| As zonas por bioma, a zona Comum com a receita de hoje, uns 40% do bioma na Comum no mapa sorteado, a ferramenta Zona no F2 e a taxa como multiplicador por zona | Aprovou a proposta: "Aprovado, pode seguir com essas zonas" |

As zonas:

| Bioma | Zonas, além da Comum |
| --- | --- |
| Planície | Bosque, Arbustal, Clareira, Campo florido |
| Boreal | Clareira, Samambaial (a Comum é o pinheiral fechado de hoje) |
| Colina | Mato seco, Pedregal |
| Pedra | Rochedo |
| Deserto | Dunas, Cactal |
| Neve | Campo de neve, Pinheiral nevado |

A Montanha, a Praia, a Água rasa, a Água profunda e o Vau ficam só com a Comum.

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A tabela se chama `biome_zones`, e não `zones` | O [game-data/architecture.md](../game-data/architecture.md) guarda o nome `zones` para a seleção de zonas antiga (`evolutions.zone_id`, `creature_instances.caught_zone_id`) |
| A zona Comum de cada bioma é uma linha, com o mesmo id e o mesmo slug do bioma (ids 1 a 11) | O cliente acha a receita pelo slug da zona, e a Comum cai direto na receita de hoje. A linha também deixa o dono pôr uma exceção na Comum, como "esse Ecobeast só no Bosque" |
| O hexágono guarda a zona só quando ela não é a Comum (`zone` fora do JSON, `biome_zone_id` nulo) | Os mapas e as ilhas de hoje já ficam na Comum, sem migração de dados |
| A taxa numa zona é `species_biomes.rate × rate_percent / 100`, com `species_biome_zones` guardando só as exceções (sem linha, 100) | Com a tabela vazia, o sorteio é o mesmo de hoje; o dono só escreve o que muda |
| A parte de cada zona no bioma (`share`) e a ordem das manchas (`sort_order`) moram em `biome_zones` | É dado de design, ajustável no painel, como as taxas |
| As manchas saem de um ruído próprio, de um sorteio separado tirado da seed, com as zonas em faixas na ordem de `sort_order` | O terreno da seed não muda, e as zonas vizinhas fazem sentido (a Clareira encosta no Campo florido, o Arbustal no Bosque) |
| As exceções iniciais são poucas, na [fase 01](01-zone-records.md) | Para a zona já mudar alguma coisa no jogo; o dono ajusta depois |
| As receitas das zonas usam só os 51 tipos de decoração de hoje | Sem arte nova nesta iniciativa |

## Fora do escopo

- As variantes dos biomas (pedido do dono para depois).
- Arte nova de decoração ou de chão por zona.
- A zona mudar a cor do chão, a música, os vagalumes ou a luz da noite.
- A zona nas equipes dos Domadores NPC e no Ecobeast posto pelo debug.
- Pintar zonas por carimbo (a ferramenta Carimbo não leva a zona).

## Pré-requisitos

- [biome-encounters](../biome-encounters/), [day-phase-spawns](../day-phase-spawns/): o sorteio do mapa.
- [nature-variety](../nature-variety/): as receitas de hoje.
- [map-editor](../map-editor/), [islands](../islands/): o F2 e as ilhas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-zone-records](01-zone-records.md) | As tabelas, as zonas no gerador e quem nasce por zona | concluída |
| 2 | [02-zone-plants](02-zone-plants.md) | As receitas de plantas por zona, no mapa, no tabuleiro e no F1 | concluída (falta o dono conferir no jogo) |
| 3 | [03-island-zones](03-island-zones.md) | A zona nos hexágonos das ilhas e a ferramenta Zona do F2 | concluída (falta o dono conferir no F2 e no F5) |

## Resultado da verificação

Em 2026-11-19:

- **Servidor:** `npm run lint`, `npm run typecheck` e `npm test` (1.019 testes) passam. A suíte e2e deu 686 de 689: as 2 falhas do `seed.e2e` de antes (espécies que só estão no banco) e uma queda de conexão com o banco no `team.e2e` ("some ao reordenar"), que passou ao rodar de novo.
- **`assignZones`:** em 5 seeds, cada zona fica a até 1 hexágono da parte dela; o terreno é o mesmo de `generateMap`, e a mesma seed dá as mesmas zonas.
- **O sorteio:** sem exceção, a zona tem a mesma chance da Comum; com 200%, o dobro; com 0%, a espécie não nasce nela.
- **As plantas:** o hash das decorações de 1.800 hexágonos da Comum, em 9 biomas, é o mesmo antes e depois da mudança. Uma foto com as 19 zonas de terra lado a lado mostrou cada uma com a cara da tabela.
- **O F2:** numa cena temporária, a ferramenta Zona pintou o Bosque só nos 6 hexágonos de Planície de um pincel de raio 1, o desfazer e o botão de trás voltaram à Comum, a ferramenta Bioma limpou a zona, e a zona foi para o JSON salvo. A foto do F2 mostra o painel e a cor das zonas por cima.
- **O jogo:** o catálogo baixa sem erro, e `godot --headless --path client --quit-after 30` sobe sem erro de script.
- **Falta o dono:** uma luta começada num Bosque e uma ilha com zonas salva, publicada e aberta em Explorar.
