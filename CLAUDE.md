# Ecobeast — contexto do projeto

Jogo mobile (Android/iOS, retrato) inspirado no Pokémon Simulator 4.5 (Birdiesoft, 2004): capturar, treinar e batalhar criaturas por menus e batalhas por turnos, sem mundo aberto. O jogo será **só online**, com o servidor decidindo as regras; no MVP ainda não há servidor, e tudo roda no cliente atrás de serviços.

## Monorepo

```
.specs/     specs de todo o projeto (cliente e servidor)
GDD.md      regras, fórmulas e conteúdo
TELAS.md    as 16 telas do protótipo
client/     o jogo: Godot 4.7 com GDScript (regras em client/CLAUDE.md)
server/     a API: NestJS + Prisma sobre o Supabase (Postgres, Auth, Storage); ainda não existe
```

O Godot fala **só com o NestJS**, nunca com o banco nem com a API automática do Supabase. Decisões da stack em `.specs/roadmap.md`; layout do repositório em `.specs/foundation/architecture.md`.

O dono do projeto é iniciante em Godot: explique conceitos do motor (cenas, nós, autoloads, `class_name`, sinais) quando aparecerem pela primeira vez.

## Comece pelas specs

Toda entrega nasce de uma spec em `.specs/`. Antes de implementar, leia:

1. `.specs/README.md` — convenção, regras e a ordem das fases do MVP.
2. O `README.md` e o `architecture.md` da iniciativa.
3. A spec da fase (`NN-assunto.md`).

A spec é a fonte da verdade. Se a implementação precisar divergir, atualize a spec no mesmo commit e diga o motivo. Documentos de design: `GDD.md` (regras, fórmulas, conteúdo) e `TELAS.md` (as 16 telas do protótipo).

## Regras de todo o projeto

- **Nunca** usar nomes, termos ou visuais do Pokémon no jogo. Use o vocabulário de `.specs/glossary.md`: Ecobeast, Domador, Esfera de Vínculo, Bestiário, Elemento, Técnica, Traço, Temperamento, Genes, Treino, Santuário, Arena, Prismático, Ancestral, Ascensão, Refúgio.
- **O servidor é a autoridade:** regras de jogo (stats, dano, captura, recompensas) são decididas pelo servidor quando ele existir; o cliente só exibe.
- **Dados de design** são tabelas relacionais (ids estáveis, FKs `<singular>_id`), descritas em `.specs/game-data/architecture.md`. O estado do jogador guarda só ids do catálogo.
- Textos do jogador em pt-BR.
- Sem segredos no repositório (chaves do Supabase, senhas, tokens).
- Um commit por fase; commits só de spec usam `chore`, os de implementação `feat` ou `fix`.

## Escopo atual (MVP de estrutura, concluído)

Tela de entrada com o nome do Domador, escolha de 1 entre 3 Ecobeasts iniciais (Fogo, Água, Flora) e Hub com todas as features abrindo telas placeholder. O resto está em `.specs/roadmap.md`.
