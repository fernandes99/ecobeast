# GDD — Jogo de Criaturas Mobile (Unity)

Oct 14, 2026 · @Roberto Fernandes

## Referência: Pokémon Simulator 4.5

O Pokémon Simulator 4.5 é um jogo freeware para Windows feito pela Birdiesoft, lançado em 14/07/2004, focado em capturar, treinar e batalhar — quase sem exploração de mundo. Tudo acontece por menus e texto, com sprites estáticos. ([Birdiesoft](https://birdiesoft.dk/software.php?id=2), [Malavida](https://www.malavida.com/br/soft/pokemon-simulator/))

O que o jogo tem, e que vale replicar com identidade própria:

- **Loop central por menus:** um painel com suas criaturas e um painel de Ações (lutar contra treinador, lutar contra criatura selvagem).
- **Batalha por turnos em texto:** escolhe o golpe, lê o resultado do seu ataque e do inimigo, até vencer, perder ou fugir; status sempre visíveis ao lado.
- **Captura em massa:** todas as 386 espécies capturáveis e até 10.000 criaturas guardadas.
- **Economia simples:** o dinheiro das vitórias compra bolas de captura e poções, e também serve para apostas.
- **Segredo desbloqueável:** capturar uma criatura lendária específica ativa uma função oculta.
- **Evolução por treino** e sistema de tipos idêntico ao original.

Pontos fracos que você pode corrigir: sem troca de criatura durante a luta, sem gráficos/animações, sem progressão de mundo, sem online. Para o mobile, a oportunidade é manter a simplicidade "menu + batalha rápida" e adicionar progressão, coleção e PvP assíncrono.

## Ideias de nome para o app

Minha recomendação é **Ecobeast** ou **Animara**: curtos, pronunciáveis em PT/EN e sem palavras da Nintendo. Antes de decidir, pesquise cada um no INPI, no USPTO/EUIPO, na Play Store e na App Store.

| Nome | Ideia por trás | Combina com a entidade |
| --- | --- | --- |
| Ecobeast | Eco (natureza, elementos) + beast | Ecobeast |
| Animara | Anima (alma) + ara (terra) | Ânimas |
| Kindra Tamers | Kin (parentesco) + domadores | Kindras |
| Elemora | Elemento + memória | Elemoras |
| Wildlink | Vínculo com o selvagem | Links / Wildlings |
| Spiriforge | Espírito + forja (evolução) | Spiris |
| Mythbound | Ligado a um mito | Myths |
| Totemica | Totem + mágica | Totens |
| Feralis Arena | Feral + arena (foco em batalha) | Ferais |
| Echo Tamers | Ecos de criaturas antigas | Echoes |

Evite qualquer nome terminado em "-mon": já existe muita disputa jurídica e é o primeiro sinal de "cópia" para lojas e jogadores.

## Nome da entidade e vocabulário

Sugestão: a criatura se chama **Ecobeast** (plural Ecobeasts; em PT pode virar "Eco"). No código, use um nome neutro como `Creature` para poder trocar a marca sem refatorar.

Outras opções para a entidade: Ânima, Kindra, Feral, Spiri, Echo, Totem, Wildling.

Crie um vocabulário próprio para tudo que o jogador vê. Isso é o que mais afasta o jogo de parecer cópia:

| Conceito no Pokémon | Seu termo (sugestão) | Nome técnico no código |
| --- | --- | --- |
| Pokémon | Ecobeast | Creature |
| Treinador | Domador (Tamer) | Player / Trainer |
| Pokébola | Esfera de Vínculo (Bond Sphere) | CaptureItem |
| Pokédex | Bestiário (Codex) | Codex |
| Tipo | Afinidade / Elemento | ElementType |
| Golpe / Move | Técnica | Skill |
| Habilidade (Ability) | Traço | Trait |
| Natureza | Temperamento | Temperament |
| IV | Genes | Genes |
| EV | Treino | TrainingPoints |
| PC (caixas) | Santuário | Storage |
| Ginásio / Líder | Arena / Mestre de Arena | Arena / ArenaBoss |
| Shiny | Prismático | IsPrismatic |
| Lendário | Ancestral | Rarity.Ancestral |
| Evolução | Ascensão | Evolution |
| Centro Pokémon | Refúgio | HealStation |

## Features do jogo

O MVP é o Pokémon Simulator modernizado: menus, batalha 1x1 por turnos, captura, evolução e loja — offline, com save local. O resto entra depois do lançamento.

**MVP (versão 1.0)**

- [ ] Escolha do inicial (3 opções: Fogo, Água, Planta)
- [ ] Tela Home com equipe ativa (6) e menu de Ações
- [ ] Batalha selvagem por zona (zonas desbloqueiam por nível médio da equipe)
- [ ] Batalha contra domadores NPC com IA simples
- [ ] Batalha por turnos: 4 técnicas, trocar criatura, usar item, fugir
- [ ] Tipos, STAB, crítico, precisão, status (queimado, paralisado etc.)
- [ ] Captura com 3 esferas e chance baseada em HP/status
- [ ] XP, level up, aprender técnica nova (escolher qual esquecer)
- [ ] Evolução por nível
- [ ] Loja (esferas, poções, curas de status) e Refúgio (cura grátis)
- [ ] Santuário (armazenamento ilimitado, filtros por tipo/nível)
- [ ] Bestiário (visto / capturado)
- [ ] 8 Arenas + Liga final; desbloqueio secreto ao capturar o Ancestral
- [ ] Save local (JSON criptografado) + backup na nuvem opcional
- [ ] 60 a 90 espécies no lançamento

**Pós-lançamento**

- Evoluções por item, amizade, horário e troca
- Criação (breeding) e herança de Genes e técnicas
- Prismáticos (1/2048) e eventos sazonais
- PvP assíncrono (seu time controlado pela IA contra o de outro jogador) e ranking
- Torre de batalhas / modo roguelike com times aleatórios
- Apostas em batalhas NPC com moeda do jogo (homenagem ao original; evite dinheiro real por causa das regras de jogos de azar)
- Batalha automática e velocidade 2x para farm
- Trocas entre jogadores
- Conquistas e missões diárias

**Monetização sugerida (sem pay-to-win)**

- Anúncio recompensado (cura grátis, XP em dobro por 30 min)
- Passe de temporada cosmético
- Remover anúncios (compra única)
- Skins e molduras de cartas do Bestiário

## Tipos (Elementos) e efetividade

Proposta: 14 elementos, com uma tabela própria (não a cópia da tabela do Pokémon). Cada criatura tem 1 ou 2 elementos; com 2, os multiplicadores se multiplicam (2 × 2 = 4x, 0,5 × 0,5 = 0,25x).

| Elemento | Forte contra (causa 2x) | Pouco eficaz contra (0,5x) | Sem efeito (0x) | Fraco a (recebe 2x) |
| --- | --- | --- | --- | --- |
| Fogo | Flora, Gelo, Metal | Fogo, Água, Terra, Arcano | — | Água, Terra |
| Água | Fogo, Terra | Água, Flora, Arcano | — | Volt, Flora |
| Flora | Água, Terra | Fogo, Flora, Vento, Toxina, Metal, Arcano | — | Fogo, Gelo, Vento, Toxina |
| Volt | Água, Vento | Volt, Flora, Arcano | Terra | Terra |
| Terra | Fogo, Volt, Toxina, Metal | Flora | Vento | Água, Flora, Gelo |
| Vento | Flora, Toxina | Volt, Metal, Terra | — | Volt, Gelo |
| Gelo | Flora, Terra, Vento, Arcano | Fogo, Água, Gelo, Metal | — | Fogo, Metal |
| Metal | Gelo, Fera | Fogo, Água, Volt, Metal | — | Fogo, Terra |
| Toxina | Flora, Luz | Toxina, Terra, Sombra | Metal | Terra, Vento, Mente |
| Mente | Fera, Toxina | Mente, Metal | Sombra | Sombra |
| Sombra | Mente, Luz | Sombra, Arcano | — | Luz |
| Luz | Sombra, Arcano | Luz, Fogo, Metal | — | Toxina, Sombra |
| Fera | — | Metal, Terra | — | Metal, Mente |
| Arcano | Arcano | Metal, Luz | — | Gelo, Luz, Arcano |

Resistências (recebe 0,5x) saem da mesma tabela, lida pela coluna do defensor. No código, guarde tudo numa matriz `float[14,14]` (atacante × defensor) com valor padrão 1. Fera é o elemento "neutro" e Arcano é o elemento raro dos Ancestrais.

## Atributos técnicos da criatura

Separe em duas camadas: a **Espécie** (dados fixos, um ScriptableObject por espécie) e a **Instância** (cada criatura que o jogador tem, salva em JSON). Todas as Ecobeasts da mesma espécie compartilham a primeira; a segunda é única.

**Espécie — `CreatureSpecies` (dados de design)**

| Campo | Tipo | Exemplo / observação |
| --- | --- | --- |
| id | int | 25 (número no Bestiário) |
| speciesName | string | "Fagulho" |
| description | string | Texto do Bestiário |
| primaryElement / secondaryElement | ElementType | Fogo / Nenhum |
| baseHP, baseAtk, baseDef, baseSpAtk, baseSpDef, baseSpd | int (1–255) | 45, 60, 40, 65, 50, 70 |
| baseStatTotal | int (calculado) | 330; iniciais ~310, finais ~530, Ancestrais ~600 |
| growthRate | enum | Fast, Medium, Slow, Erratic (curva de XP) |
| baseXpYield | int | XP dado ao ser derrotado |
| trainingYield | StatBlock | Pontos de treino dados ao vencedor (ex.: +1 Spd) |
| captureRate | int (3–255) | 45 = difícil, 255 = fácil |
| rarity | enum | Comum, Incomum, Raro, Épico, Ancestral |
| possibleTraits | Trait[] | 1–2 traços normais + 1 oculto |
| learnset | List<LevelSkill> | Técnicas por nível |
| teachableSkills | Skill[] | Aprendidas por item/tutor |
| evolutions | List<EvolutionRule> | Para quem evolui e como |
| genderRatio | float | 0,5 = 50% macho; -1 = sem gênero |
| heightM, weightKg | float | Para o Bestiário e técnicas baseadas em peso |
| habitatZones | Zone[] | Onde aparece selvagem |
| spawnWeight | int | Peso no sorteio de encontro |
| sprite, backSprite, icon, cry | assets | Addressables |

**Instância — `CreatureInstance` (dados salvos)**

| Campo | Tipo | Observação |
| --- | --- | --- |
| uid | string (GUID) | Identificador único |
| speciesId | int | Aponta para a espécie |
| nickname | string | Apelido opcional |
| level | int (1–100) |  |
| currentXp | int |  |
| currentHP | int |  |
| genes | StatBlock (0–31 cada) | Sorteados na captura, definem o potencial |
| trainingPoints | StatBlock (0–252 cada, 510 total) | Ganhos ao vencer batalhas |
| temperament | enum (25) | +10% em um stat, -10% em outro |
| trait | Trait | Traço passivo |
| skills | SkillSlot[4] | Técnica + PP atual |
| status | StatusCondition | Queimado, Paralisado, Sono etc. |
| heldItem | Item | Item equipado |
| gender | enum |  |
| isPrismatic | bool | Versão rara de cor |
| bond | int (0–255) | Amizade; pode gatilhar evolução |
| originalTamer, caughtAt, caughtZone | string/data | Para trocas e histórico |

Stats calculados em batalha (não salvos): HP, Atk, Def, SpAtk, SpDef, Spd + modificadores temporários de -6 a +6, Precisão e Evasão.

## Fórmulas

Mecânicas de jogo não são protegidas por direito autoral, então você pode usar fórmulas no mesmo estilo. Ajuste as constantes para ter identidade própria e equilíbrio no mobile.

**Stats**

```latex
HP = \left\lfloor \frac{(2 \cdot Base + Genes + \lfloor Treino/4 \rfloor) \cdot Nivel}{100} \right\rfloor + Nivel + 10
```

```latex
Stat = \left( \left\lfloor \frac{(2 \cdot Base + Genes + \lfloor Treino/4 \rfloor) \cdot Nivel}{100} \right\rfloor + 5 \right) \cdot Temperamento
```

Temperamento = 1,1, 0,9 ou 1,0. Modificador de estágio em batalha: +n → (2+n)/2; −n → 2/(2+n).

**Dano**

```latex
Dano = \left( \frac{\left(\frac{2 \cdot Nivel}{5} + 2\right) \cdot Poder \cdot \frac{Atk}{Def}}{50} + 2 \right) \cdot STAB \cdot Tipo \cdot Critico \cdot Aleatorio \cdot Outros
```

- Atk/Def: físico usa Atk × Def; especial usa SpAtk × SpDef
- STAB = 1,5 se o elemento da técnica for igual a um elemento do atacante
- Tipo = produto dos multiplicadores (0 a 4)
- Crítico = 1,5 com chance de 1/24 (estágios sobem a chance)
- Aleatório = valor entre 0,85 e 1,0
- Outros = queimado (×0,5 no físico), clima, item, traço

**Ordem do turno:** prioridade da técnica primeiro; empate decidido por Velocidade (paralisado = ×0,5); empate total = sorteio.

**XP ganho**

```latex
XP = \frac{baseXpYield \cdot NivelInimigo}{7} \cdot (1{,}5 \text{ se domador}) \cdot bonusItem
```

Curvas de XP total por nível: Fast = 0,8·n³; Medium = n³; Slow = 1,25·n³.

**Captura**

```latex
a = \frac{(3 \cdot HP_{max} - 2 \cdot HP_{atual}) \cdot captureRate \cdot bonusEsfera}{3 \cdot HP_{max}} \cdot bonusStatus
```

Chance de captura = min(a / 255, 1). Bônus de esfera: comum 1, grande 1,5, ultra 2. Bônus de status: sono ou congelado 2,5; paralisado, queimado ou envenenado 1,5. Para dar emoção, faça 3 "tremidas" de animação antes de revelar o resultado.

## Técnicas (Skills)

Cada técnica é um ScriptableObject `SkillData` com dados e uma lista de efeitos reutilizáveis. Assim você cria centenas de técnicas combinando poucos efeitos, sem código novo.

**Campos de `SkillData`**

| Campo | Tipo | Observação |
| --- | --- | --- |
| id, skillName, description | int / string | Nome sempre original |
| element | ElementType | Define STAB e efetividade |
| category | enum | Física, Especial, Suporte |
| power | int (0–250) | 0 em técnicas de suporte |
| accuracy | int (0–100) | 0 = nunca erra |
| maxPP | int (5–40) | Usos antes de descansar |
| priority | int (-7 a +5) | +1 ataca primeiro |
| critStage | int | 0 normal, 1 = crítico alto |
| target | enum | Inimigo, Si mesmo, Todos |
| makesContact | bool | Ativa traços de contato |
| hits | Vector2Int | (1,1) normal; (2,5) multi-golpe |
| effects | List<SkillEffect> | Efeitos com chance |
| vfx, sfx, animation | assets |  |

**Efeitos reutilizáveis (`SkillEffect`)**

- ApplyStatus(status, chance) — ex.: 10% de queimar
- ModifyStat(alvo, stat, estágios, chance) — ex.: −1 Def do inimigo
- Heal(% do HP máx.) / Drain(% do dano causado)
- Recoil(% do dano causado)
- Flinch(chance) — inimigo perde a vez se for mais lento
- MultiTurn — carrega no turno 1, ataca no turno 2
- FixedDamage(valor ou = nível)
- SetWeather(clima, turnos)
- Protect — bloqueia o golpe neste turno
- Switch — troca após atacar

**Exemplos (nomes originais)**

| Técnica | Elemento | Categoria | Poder | Precisão | PP | Efeito |
| --- | --- | --- | --- | --- | --- | --- |
| Arranhão | Fera | Física | 40 | 100 | 35 | — |
| Faísca Rápida | Fogo | Especial | 40 | 100 | 25 | 10% queimar |
| Chama Espiral | Fogo | Especial | 90 | 100 | 15 | 10% queimar |
| Erupção Solar | Fogo | Especial | 120 | 85 | 5 | Recuo 33% |
| Jato de Maré | Água | Especial | 40 | 100 | 25 | — |
| Chicote de Raiz | Flora | Física | 45 | 100 | 25 | — |
| Seiva Vital | Flora | Especial | 60 | 100 | 15 | Drena 50% |
| Choque Curto | Volt | Especial | 40 | 100 | 30 | 10% paralisar |
| Investida Veloz | Fera | Física | 40 | 100 | 30 | Prioridade +1 |
| Rugido Feroz | Fera | Suporte | — | 100 | 30 | −1 Atk inimigo |
| Couraça | Metal | Suporte | — | — | 20 | +1 Def próprio |
| Névoa Tóxica | Toxina | Suporte | — | 90 | 15 | Envenena |
| Lâmina Sombria | Sombra | Física | 70 | 100 | 15 | Crítico alto |
| Prisma | Luz | Especial | 80 | 100 | 10 | 20% −1 SpDef |

## Técnicas por nível (learnset)

Cada espécie tem uma lista `LevelSkill { int level; SkillData skill; }`. Ao subir de nível, o jogo verifica a lista; se já houver 4 técnicas, o jogador escolhe qual esquecer ou desiste da nova.

Regras práticas:

- Nível 1: 2 técnicas (1 de dano Fera + 1 de suporte)
- Primeira técnica do próprio elemento entre os níveis 5 e 9
- Uma técnica nova a cada 3–5 níveis até o 50; depois a cada 7–10
- Nível 0 = aprende ao evoluir (técnica marcante da forma nova)
- Formas evoluídas herdam a lista da forma anterior, com as técnicas fortes um pouco mais tarde
- Selvagens chegam com as 4 últimas técnicas aprendidas até o nível delas

**Exemplo: linha de Fagulho (Fogo)**

| Nível | Fagulho | Brasalobo | Infernolobo |
| --- | --- | --- | --- |
| 1 | Arranhão, Rugido Feroz | Arranhão, Rugido Feroz | Arranhão, Rugido Feroz |
| 0 (ao evoluir) | — | Mordida Brasa | Lâmina Sombria |
| 7 | Faísca Rápida | Faísca Rápida | Faísca Rápida |
| 10 | Investida Veloz | Investida Veloz | Investida Veloz |
| 13 | Fumaça Densa (−1 precisão) | Fumaça Densa | Fumaça Densa |
| 19 | Presa Ígnea (65, 10% queimar) | Presa Ígnea | Presa Ígnea |
| 25 | Uivo (+1 Atk) | Uivo | Uivo |
| 31 | Chama Espiral | — | — |
| 34 | — | Chama Espiral | Chama Espiral |
| 42 | — | Couraça de Cinzas (+1 Def, +1 SpDef) | Couraça de Cinzas |
| 48 | — | — | Garra do Eclipse (Sombra, 90) |
| 55 | — | Erupção Solar | Erupção Solar |

Técnicas de tutor e de item (teachableSkills) cobrem outros elementos para dar variedade ao time.

## Evoluções (Ascensão)

Cada espécie tem uma lista de `EvolutionRule { CreatureSpecies target; EvolutionTrigger trigger; int level; Item item; int minBond; TimeOfDay time; Zone zone; }`. A regra é checada após a batalha (nível, vínculo) ou ao usar um item; o jogador pode cancelar segurando o botão.

| Gatilho | Exemplo | Quando entra |
| --- | --- | --- |
| Nível | Fagulho → Brasalobo no nível 16 | MVP |
| Item | Gotículo + Pedra da Maré → Marisgarra | Pós-lançamento |
| Vínculo | Bond ≥ 220 ao subir de nível | Pós-lançamento |
| Horário | Nível 20 à noite → forma Sombra | Pós-lançamento |
| Zona | Subir de nível na Caverna Gélida → forma Gelo | Pós-lançamento |
| Troca | Evolui ao ser trocado com outro jogador | Com trocas |
| Ramificada | Mesmo pré-evolução, destino pelo Temperamento | Pós-lançamento |

**Exemplo de linha evolutiva**

| Forma | Elementos | Nível | HP / Atk / Def / SpA / SpD / Spd | Total |
| --- | --- | --- | --- | --- |
| Fagulho | Fogo | 1–15 | 44 / 58 / 42 / 60 / 48 / 66 | 318 |
| Brasalobo | Fogo | 16–35 | 60 / 78 / 56 / 80 / 62 / 84 | 420 |
| Infernolobo | Fogo / Sombra | 36+ | 78 / 108 / 72 / 100 / 76 / 101 | 535 |

Ao evoluir: mantém nível, XP, Genes, Treino, Temperamento, técnicas e vínculo; recalcula stats; o traço vai para o slot equivalente da nova espécie; aprende a técnica de nível 0.

## Status, traços, temperamentos e itens

**Status principais** (só um por vez, persistem fora da batalha)

| Status | Efeito | Imune |
| --- | --- | --- |
| Queimado | −1/16 HP por turno; dano físico ×0,5 | Fogo |
| Envenenado | −1/8 HP por turno | Toxina, Metal |
| Paralisado | Velocidade ×0,5; 25% de perder a vez | Volt |
| Sono | Não age por 1–3 turnos | — |
| Congelado | Não age; 20% de descongelar por turno | Gelo |

Status voláteis (somem ao trocar): Confuso (33% de se atingir, 2–5 turnos), Amedrontado (perde 1 turno), Preso (não pode trocar).

**Traços (passivas) — exemplos**

| Traço | Efeito |
| --- | --- |
| Fúria Ardente | +50% em técnicas de Fogo com HP ≤ 1/3 |
| Pele Úmida | Imune a técnicas de Fogo e recupera 1/4 do HP ao recebê-las |
| Olhar Gélido | −1 Atk do inimigo ao entrar |
| Casca Dura | Imune a críticos |
| Espinhos | Contato causa 1/8 do HP ao atacante |
| Levitação | Imune a Terra |
| Instinto | +1 Spd ao derrotar um inimigo |

**Temperamentos:** 25 combinações de +10% em um stat e −10% em outro (5 são neutros). Ex.: Ousado (+Atk −SpA), Calmo (+SpD −Atk), Ágil (+Spd −Def).

**Itens**

| Categoria | Exemplos |
| --- | --- |
| Captura | Esfera de Vínculo, Grande Esfera, Ultra Esfera, Esfera Noturna |
| Cura | Poção (20 HP), Super Poção (60), Tônico Total, Antídoto, Pomada |
| Batalha (segurados) | Amuleto Ígneo (+20% Fogo), Fruta de Cura, Cinto da Resistência |
| Evolução | Pedra da Maré, Pedra Solar, Cristal Lunar |
| Treino | Doce Raro (+1 nível), Vitaminas (+Treino), Manual de Técnica |

## Arquitetura no Unity

Dados de design em ScriptableObjects, estado do jogador em classes C# simples serializadas em JSON, e a batalha como uma máquina de estados pura (sem MonoBehaviour), para ser testável e reaproveitável no PvP.

1. **Data (ScriptableObjects):** CreatureSpecies, SkillData, TraitData, ItemData, ElementChart, ZoneData, TamerData
2. **Model (runtime/save):** CreatureInstance, PlayerSave, Inventory, Storage
3. **Battle Core:** BattleStateMachine (Início → Escolha → Ordenação → Execução → Fim de turno → Checagem de fim), DamageCalculator, CaptureCalculator, BattleAI
4. **UI:** telas com UI Toolkit ou uGUI, ouvindo eventos da batalha (`OnDamage`, `OnStatusApplied`, `OnFaint`)
5. **Serviços:** SaveService (JSON + AES), AdsService, IAPService, CloudSaveService

```csharp
[CreateAssetMenu(menuName = "Ecobeast/Species")]
public class CreatureSpecies : ScriptableObject {
    public int id;
    public string speciesName;
    public ElementType primary, secondary;
    public StatBlock baseStats;          // HP, Atk, Def, SpAtk, SpDef, Spd
    public GrowthRate growthRate;
    public int baseXpYield, captureRate;
    public StatBlock trainingYield;
    public Rarity rarity;
    public TraitData[] possibleTraits;
    public List<LevelSkill> learnset;
    public SkillData[] teachableSkills;
    public List<EvolutionRule> evolutions;
    public Sprite front, back, icon;
}

[System.Serializable]
public class CreatureInstance {
    public string uid;
    public int speciesId, level, currentXp, currentHP, bond;
    public string nickname;
    public StatBlock genes, trainingPoints;
    public Temperament temperament;
    public int traitId, heldItemId;
    public SkillSlot[] skills = new SkillSlot[4];
    public StatusCondition status;
    public bool isPrismatic;
}
```

Dicas: use Addressables para sprites e sons; carregue os dados das espécies de uma planilha (CSV → ScriptableObject por script de editor) para balancear sem abrir o Unity; salve apenas IDs (nunca referências de asset) no JSON.

## Cuidados para não esbarrar em Pokémon

O gênero "capturar e batalhar criaturas" é livre; o risco está em copiar nomes, visuais e textos específicos. Não sou advogado — antes de publicar, vale uma consulta rápida com um especialista em propriedade intelectual.

- Nenhuma espécie, técnica, item ou lugar com nome igual ou parecido com o original
- Designs de criatura próprios: nada de "rato amarelo elétrico" ou silhuetas reconhecíveis
- Nada de "-mon", "Poké", Pokébola vermelha e branca, Pokédex ou fontes e cores da marca
- Tabela de tipos própria (como a desta proposta), sem copiar textos, sons ou músicas
- Use o vocabulário próprio também nas lojas, no marketing e nas palavras-chave
- Registre a marca do app no INPI antes do lançamento

## Próximos passos

- [ ] Escolher nome do app e da entidade e checar disponibilidade (INPI, lojas, domínio)
- [ ] Fechar a tabela de 14 elementos e montar a matriz no Unity
- [ ] Criar planilha com as 60–90 espécies (stats, elementos, evoluções)
- [ ] Criar ~80 técnicas e ~20 traços
- [ ] Prototipar o Battle Core em C# puro com testes
- [ ] Tela de batalha + captura + save local
- [ ] Arte das 3 linhas iniciais para validar o estilo visual

## Fontes

- [Birdiesoft — Pokémon Simulator](https://birdiesoft.dk/software.php?id=2)
- [Malavida — Pokemon Simulator 4.5](https://www.malavida.com/br/soft/pokemon-simulator/)
- [Informer — POKéMON Simulator 4.5](https://pok-mon-simulator.informer.com/)
- [Baixaki — Pokémon Simulator](https://www.baixaki.com.br/jogos/utilidades-para-jogos/pokemon-simulator/windows)
