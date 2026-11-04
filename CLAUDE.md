# Ecobeast — contexto do projeto

Jogo mobile (Android/iOS, retrato) inspirado no Pokémon Simulator 4.5 (Birdiesoft, 2004): capturar, treinar e batalhar criaturas por menus e batalhas por turnos, sem mundo aberto. O jogo é **só online**, com o servidor decidindo as regras. O catálogo (`GET /v1/catalog`) e o jogador (`/v1/me`) já vêm do servidor, com login pelo Google; o progresso só existe no banco.

## Monorepo

```
.specs/     specs de todo o projeto (cliente e servidor)
GDD.md      regras, fórmulas e conteúdo
TELAS.md    as 16 telas do protótipo
client/     o jogo: Godot 4.7 com GDScript (regras em client/CLAUDE.md)
server/     a API: NestJS + Prisma sobre o Supabase (Postgres, Auth, Storage) (regras em server/CLAUDE.md)
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

- **Nunca** usar nomes, termos ou visuais do Pokémon no jogo. Use o vocabulário de `.specs/glossary.md`: Ecobeast, Domador, Esfera de Vínculo, Bestiário, Elemento, Técnica, Traço, Temperamento, Genes, Treino, Santuário, Arena, Prismático, Ancestral, Evolução, Refúgio.
- **O servidor é a autoridade:** regras de jogo (stats, dano, captura, recompensas) são decididas pelo servidor; o cliente só exibe.
- **Dados de design** são tabelas relacionais (ids estáveis, FKs `<singular>_id`), descritas em `.specs/game-data/architecture.md`. Moram no banco (schema `ecobeasts`) e se editam pelo painel do Supabase. O estado do jogador guarda só ids do catálogo.
- Textos do jogador em pt-BR. A exceção são os nomes de Ecobeast, que não ficam em português e precisam ser entendidos em qualquer país. Eles podem juntar duas palavras, menos os 3 iniciais e suas evoluções, que usam palavras inventadas (Ruvo, Nilu, Elu).
- Sem segredos no repositório (chaves do Supabase, senhas, tokens).
- Um commit por fase; commits só de spec usam `chore`, os de implementação `feat` ou `fix`.

## Escopo atual (MVP de estrutura, concluído)

Tela de entrada com o nome do Domador, escolha de 1 entre 3 Ecobeasts iniciais (Fogo, Água, Flora) e Hub com todas as features abrindo telas placeholder. Depois dele, a iniciativa `backend-api` (concluída): banco no Supabase, API de leitura do catálogo com docs em `/docs` e o jogo baixando o catálogo da API. Depois, a `auth-google` (concluída): login com Google pelo navegador e o jogador morando no servidor. Depois, a `battle-core` e a `battle-screen` (concluídas): a batalha decidida pelo servidor e jogada a partir de Explorar zona. Depois, o `heal-station` (concluído): o Refúgio cura a equipe, de graça por enquanto. Depois, a `wild-battle` (concluída): Explorar zona abre um mapa hexagonal gerado pelo servidor, e a batalha sai dele. Depois, a `inventory-shop` (concluída): Loja, Mochila e o uso de itens no mapa e na luta. Depois, a `capture` (concluída): Esferas na luta, com o Ecobeast entrando na Esfera em um carregamento, sem arremesso nem tremidas. Depois, a `team-and-storage` (concluída): as telas Equipe e Santuário, e a troca de quem está em campo durante a luta. Depois, a `biome-encounters` (concluída): Ecobeasts nascem no mapa por taxa de bioma, e Procurar enfrenta um do hexágono do Domador. Depois, a `progression` (concluída): XP dividido entre quem lutou, subir de nível, Técnicas novas, Evolução que pode ser cancelada e moedas ao vencer ou perder para um selvagem. O resto está em `.specs/roadmap.md`.
