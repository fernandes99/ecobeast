# 03. Aba Genes

- **Status:** concluída
- **Depende de:** [02-details-screen](02-details-screen.md)

## Contexto

Os Genes de cada criatura são sorteados de 0 a 31 por stat quando ela nasce, e o servidor já os envia ao jogo. A tela de detalhes os deixava de fora, mas o dono quer saber se um Ecobeast tem Genes raros, com uma pontuação final. Esta fase reverte aquela decisão: entram uma aba Genes, a soma dos seis e uma raridade calculada pelo servidor.

## Escopo

- Regra da pontuação e da raridade dos Genes, no servidor.
- `genes_total` e `genes_rank` em cada criatura.
- Aba Genes na tela de detalhes.

## Fora do escopo

- Treino na tela.
- Mudar como os Genes são sorteados.
- Filtrar ou ordenar por raridade dos Genes (entra no `team-and-storage`, se fizer sentido).
- Guardar a pontuação no banco: ela é sempre calculada.

## Requisitos

**Servidor**

- **RF-01:** `genesTotal(genes)` soma os 6 Genes, de 0 a 186.
- **RF-02:** `geneRank(total)` devolve a faixa, _a revisar_:

| Pontuação | `slug`        | `name`      | Chance  |
| --------- | ------------- | ----------- | ------- |
| 0–109     | `common`      | Comum       | 76,2%   |
| 110–129   | `uncommon`    | Incomum     | 18,4%   |
| 130–144   | `rare`        | Raro        | 4,4%    |
| 145–159   | `epic`        | Épico       | 0,9%    |
| 160–186   | `exceptional` | Excepcional | 0,08%   |

- **RF-03:** Cada criatura do JSON do jogador ganha `genes_total` e `genes_rank: { "slug", "name" }`, documentados no OpenAPI.

**Jogo**

- **RF-04:** A tela passa a ter quatro abas, nesta ordem: Resumo, Atributos, Genes e Técnicas.
- **RF-05:** A aba Genes mostra "Pontuação", `genes_total`, "/ 186" e um selo com o nome da raridade.
- **RF-06:** O selo tem a cor da raridade, de `UiPalette.GENE_RANK_COLORS`, com texto legível sobre ela.
- **RF-07:** Abaixo, uma linha por stat, na ordem de `StatBlock.SLUGS`: nome curto, barra de 0 a 31 e o valor.
- **RF-08:** Um Gene 31 fica com a barra e o valor em `WARNING`; os outros, com a barra em `ACCENT` e o valor em branco.
- **RF-09:** A tela não calcula a pontuação nem a raridade: usa o que o servidor mandou.

## Critérios de aceite

- [x] Em testes de unidade, 109 é Comum; 110, Incomum; 129, Incomum; 130, Raro; 144, Raro; 145, Épico; 159, Épico; 160, Excepcional; 0, Comum; e 186, Excepcional.
- [x] Um inicial novo traz `genes_total` igual à soma dos `genes`, e `genes_rank` da faixa dela.
- [x] O OpenAPI tem os dois campos.
- [x] A aba Genes mostra os mesmos números que o servidor mandou, e a pontuação e o selo batem com eles.
- [x] Um Gene 31 aparece em dourado, e um Gene 30, não.
- [x] As cinco raridades têm selos com cores diferentes e texto legível.
- [x] As quatro abas cabem em uma linha, sem cortar texto, e a aba Genes não precisa de rolagem.
- [x] Trocar a raridade de faixa no servidor muda a tela sem mudar o jogo.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam, e o jogo roda sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `server/src/domain/rules/genes.ts` e `genes.spec.ts`: `genesTotal(genes: StatBlock): number`, `geneRank(total: number): GeneRank` e o tipo `GeneRank { slug, name }`.
- `res://screens/creature_details/gene_row.tscn` e `.gd` (`class_name GeneRow`): `set_gene(short_name: String, value: int)`, com uma cópia do preenchimento do tema, como a `HpBar`.

**Alterar**

- `server/src/player/player.mapper.ts`, `player.dto.ts` (novo `GeneRankDto`) e os testes.
- `res://domain/models/creature_instance.gd`: `genes_total`, `genes_rank_slug` e `genes_rank_name`.
- `res://ui/theme/palette.gd`: `GENE_RANK_COLORS` (`common`: `SURFACE_RAISED`; `uncommon`: `HP_HIGH`; `rare`: `WARNING`; `epic`: `#A56BE8`; `exceptional`: `#E86AA8`). As duas últimas são cores novas, _a revisar_.
- `res://screens/creature_details/creature_details_screen.tscn` e `.gd`.
- `.specs/creature-details/README.md`, `.specs/onboarding/architecture.md` (campos da criatura) e `GDD.md` (a pontuação dos Genes).

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Uma cena temporária, com o `client/override.cfg` da [02](02-details-screen.md#verificação), confere a aba contra o servidor de teste e tira capturas das cinco raridades. Ela é apagada no fim. Fica para o dono ver a aba no aparelho.

## Tarefas

- [x] Testes de `genes.ts`; ver falhar; regra (RF-01, RF-02).
- [x] Testes do mapper e dos e2e; ver falhar; campos no JSON (RF-03).
- [x] Cena temporária; ver falhar; modelo, paleta, `GeneRow` e aba (RF-04 a RF-09).
- [x] Capturas, conferência e limpeza dos arquivos temporários.
- [x] Documentos; marcar esta spec, a tabela do README e o roadmap como `concluída`; commit `feat: Genes na tela de detalhes`.

## Decisões da implementação

- **Selo Comum:** usa `SURFACE_RAISED` com texto branco, de propósito discreto. As outras raridades têm cor forte e texto escuro; a troca vem de `LIGHT_RANK_LUMINANCE`, na tela, porque o limite do `ElementBadge` deixaria o texto branco sobre as cores novas, com pouco contraste.
- **Cena temporária:** a parte de Genes foi escrita junto com a aba, então não chegou a ser vista falhando. Os testes do servidor, sim. O critério de faixa foi conferido trocando no jogo os valores recebidos, sem mudar o servidor de verdade.
- **Conferência:** 90 verificações contra a API e o banco reais, sem Google, incluindo as da [02](02-details-screen.md). Capturas das cinco raridades e do Gene 31 conferidas. `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 135 testes; `npm run test:e2e` com 213. Os temporários e o Domador de teste foram apagados.
