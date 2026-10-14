# Ecobeast — contexto do projeto

Jogo mobile (Android/iOS, retrato) feito em **Unity (C#)**, inspirado no Pokémon Simulator 4.5 (Birdiesoft, 2004): capturar, treinar e batalhar criaturas por menus e batalhas por turnos, sem mundo aberto.

Nome provisório do app e da criatura: **Ecobeast**. No código a criatura se chama sempre `Creature` (para trocar a marca sem refatorar).

## Documentos de referência (leia antes de implementar)

- `GDD.md` — Game Design Document completo: features (MVP e pós-lançamento), vocabulário próprio, 14 elementos e tabela de efetividade, atributos da espécie e da instância, fórmulas (stats, dano, XP, captura), técnicas, learnset, evoluções, status, traços, itens e arquitetura.
- `TELAS.md` — lista das 16 telas do protótipo e o que cada uma contém.

## Regras do projeto

- **Nunca** usar nomes, termos ou visuais do Pokémon. Use o vocabulário do GDD: Ecobeast (criatura), Domador, Esfera de Vínculo, Bestiário, Elemento, Técnica, Traço, Temperamento, Genes, Treino, Santuário, Arena, Prismático, Ancestral, Ascensão, Refúgio.
- Dados de design em **ScriptableObjects** (`CreatureSpecies`, `SkillData`, `TraitData`, `ItemData`, `ElementChart`, `ZoneData`, `TamerData`).
- Estado do jogador em classes C# serializáveis salvas em JSON (`CreatureInstance`, `PlayerSave`, `Inventory`, `Storage`). Salvar só IDs, nunca referências de asset.
- **Battle Core em C# puro** (sem MonoBehaviour), com testes: `BattleStateMachine`, `DamageCalculator`, `CaptureCalculator`, `BattleAI`. A UI apenas escuta eventos (`OnDamage`, `OnStatusApplied`, `OnFaint`).
- Efetividade de elementos como matriz `float[14,14]` (atacante × defensor), padrão 1.
- Técnicas montadas por composição de `SkillEffect` reutilizáveis (ApplyStatus, ModifyStat, Heal, Drain, Recoil, Flinch, MultiTurn, FixedDamage, SetWeather, Protect, Switch).
- Dados das espécies vêm de planilha CSV → ScriptableObject via script de editor.
- Assets (sprites, sons) via Addressables.

## Escopo do MVP

Escolha do inicial, Home com equipe de 6, batalha selvagem por zona, batalha contra NPC, batalha por turnos (4 técnicas, trocar, item, fugir), captura, XP/level up, evolução por nível, loja, Refúgio, Santuário, Bestiário, 8 Arenas + Liga, save local criptografado, 60–90 espécies.
