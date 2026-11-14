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
- Toda arte de construção e de decoração de cidade segue o guia de estilo `.specs/town-art/style-guide.md`.
- Sem segredos no repositório (chaves do Supabase, senhas, tokens).
- Um commit por fase; commits só de spec usam `chore`, os de implementação `feat` ou `fix`.

## Escopo atual (MVP de estrutura, concluído)

Tela de entrada com o nome do Domador, escolha de 1 entre 3 Ecobeasts iniciais (Fogo, Água, Flora) e Hub com todas as features abrindo telas placeholder. Depois dele, a iniciativa `backend-api` (concluída): banco no Supabase, API de leitura do catálogo com docs em `/docs` e o jogo baixando o catálogo da API. Depois, a `auth-google` (concluída): login com Google pelo navegador e o jogador morando no servidor. Depois, a `battle-core` e a `battle-screen` (concluídas): a batalha decidida pelo servidor e jogada a partir de Explorar zona. Depois, o `heal-station` (concluído): o Refúgio cura a equipe, de graça por enquanto. Depois, a `wild-battle` (concluída): Explorar zona abre um mapa hexagonal gerado pelo servidor, e a batalha sai dele. Depois, a `inventory-shop` (concluída): Loja, Mochila e o uso de itens no mapa e na luta. Depois, a `capture` (concluída): Esferas na luta, com o Ecobeast entrando na Esfera em um carregamento, sem arremesso nem tremidas. Depois, a `team-and-storage` (concluída): as telas Equipe e Santuário, e a troca de quem está em campo durante a luta. Depois, a `biome-encounters` (concluída): Ecobeasts nascem no mapa por taxa de bioma, e Procurar enfrenta um do hexágono do Domador. Depois, a `progression` (concluída): XP dividido entre quem lutou, subir de nível, Técnicas novas, Evolução que pode ser cancelada e moedas ao vencer ou perder para um selvagem. Depois, a `board-battle` (concluída): a luta de Explorar zona acontece num tabuleiro de hexágonos, com uma fila por Velocidade, andar 1 hexágono e agir na vez, Técnicas com alcance e marcas no chão, Mochila, Esfera, troca e fuga. A luta antiga foi apagada depois, na `legacy-battle-removal`. Depois, a `npc-tamers` (concluída): Domadores NPC sorteados no mapa, com fala no log que trava o mapa, luta obrigatória de 1×1, 2×2 ou 3×3 sem fuga nem Esfera, recompensa maior e volta ao Hub na derrota, e o Desafiar do Hub contra um Domador sorteado. Depois, a `codex` (concluída): o Bestiário, com as espécies vistas em luta e as capturadas, o detalhe com a linha evolutiva e o aviso de registro na primeira captura e na Evolução. Depois, a `battle-intro` (concluída): a transição de zoom pixelado ao entrar na luta e a música retrô original de selvagem, de Domador e de vitória. Depois, a `map-editor` (concluída): o editor de ilhas, só de desenvolvimento (F2), que cria as ilhas fixas do zero ou pelo gerador, com terreno, construções e áreas de Ecobeasts de nível fixo, e as salva no banco como rascunho até publicar. Depois, a `islands` (concluída): a ação Ilhas no Hub lista as ilhas publicadas, e Explorar numa delas mostra o mapa fixo com as construções, com os Ecobeasts nascendo pelas áreas e o Refúgio e a Loja abrindo quando o Domador entra neles. Depois, a `terrain-height` (concluída): cada hexágono tem bioma (Colina e Montanha incluídas) e altura de 0 a 10, separados, e o editor pinta a altura com a ferramenta Altura. Depois, a `island-villages` (concluída): as ilhas ganham trilhas e pisos, objetos de 1 a 4 hexágonos (casas, moinho, castelo, árvore grande) com variante, espelho e bloqueio por hexágono, e as construções viram ações, que o Domador executa ao entrar ou ao tocar num hexágono bloqueado ao lado. Depois, a `town-art` (concluída): o guia de estilo da cidade e, como tipos novos ao lado dos de antes, os prédios do Refúgio, da Loja e da Arena, as casas e os objetos de vila da cidade e as decorações de rua. Depois, a `free-props` (concluída): a grade continua sendo a regra, e a arte se solta por cima dela. O Domador anda em reta até o ponto tocado, as ilhas ganham peças soltas (só enfeite, num ponto em pixels, sem decorações sorteadas), e o editor ganha a ferramenta Peças, com os objetos de grade e as peças soltas, e a ferramenta Carimbo, que guarda e põe conjuntos prontos. O resto está em `.specs/roadmap.md`.
