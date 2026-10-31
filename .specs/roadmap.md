# Roadmap

O que vem depois do MVP de estrutura (entrada, escolha do inicial e Hub). Cada linha vira uma iniciativa em `.specs/<nome>/` quando for planejada; até lá, o status é `planejada` e o escopo é só a frase abaixo. A ordem é a sugerida, não um compromisso.

## Iniciativas do jogo 1.0

| #   | Iniciativa          | Entrega                                                                                                   | Depende de                 | Status    |
| --- | ------------------- | --------------------------------------------------------------------------------------------------------- | -------------------------- | --------- |
| 1   | [`backend-api`](backend-api/) | Banco no Supabase (todas as tabelas num `schema.prisma`), API NestJS de leitura do catálogo com docs Scalar; o jogo passa a ler o catálogo da API | MVP                        | concluída |
| 1b  | [`visual-theme`](visual-theme/) | Paleta escura em todo o jogo e o Hub no layout do protótipo do dono, com espaços para as ilustrações | MVP                        | concluída |
| 2   | [`auth-google`](auth-google/) | Login com Google pelo navegador (Supabase Auth via NestJS); o jogador passa a viver no servidor: criar Domador, escolher inicial e apagar progresso viram rotas do NestJS. Login nativo e "Entrar com a Apple" ficam para depois | backend-api                | concluída    |
| 3   | `battle-core`       | Máquina de estados da batalha, dano, ordem do turno, status, IA simples — autoridade no servidor          | backend-api                | planejada |
| 4   | `battle-screen`     | Tela de batalha (TELAS.md #5) ouvindo os eventos do battle-core                                           | battle-core                | planejada |
| 5   | `wild-battle`       | Zonas, seleção de zona (TELAS.md #4) e encontros selvagens; tabelas `zones` e `zone_encounters`           | battle-screen              | planejada |
| 6   | `capture`           | Esferas de Vínculo, fórmula de captura e animação das 3 tremidas (TELAS.md #6)                            | wild-battle, inventory-shop | planejada |
| 7   | `progression`       | XP, level up, aprender/esquecer técnica, Ascensão por nível (TELAS.md #7)                                 | battle-core                | planejada |
| 8   | `npc-tamers`        | Domadores NPC com equipe fixa e recompensa em moedas; tabela `npc_tamers`                                 | battle-screen              | planejada |
| 9   | `team-and-storage`  | Equipe com 6 slots reorganizáveis e Santuário com filtros e busca (TELAS.md #9 e #10)                     | capture                    | planejada |
| 10  | [`creature-details`](creature-details/) | Tela de detalhes da criatura (TELAS.md #8); vem antes do `battle-core`, por decisão do dono | auth-google                | em andamento |
| 11  | `inventory-shop`    | Mochila e Loja (TELAS.md #12 e #13); tabelas `items`, `item_categories`, `inventory_items`                | backend-api                | planejada |
| 12  | `heal-station`      | Refúgio: curar a equipe (TELAS.md #14)                                                                    | backend-api                | planejada |
| 13  | `codex`             | Bestiário com visto/capturado, detalhe e linha evolutiva (TELAS.md #11)                                   | wild-battle                | planejada |
| 14  | `arenas-league`     | 8 Arenas, emblemas, Liga final e desbloqueio secreto do Ancestral (TELAS.md #15)                          | npc-tamers                 | planejada |
| 15  | `profile-settings`  | Perfil com estatísticas e configurações (TELAS.md #16)                                                    | auth-google                | planejada |
| 16  | `content`           | 60–90 espécies, ~80 técnicas, ~20 traços, balanceamento                                                   | progression                | planejada |
| 17  | `release-pipeline`  | Export Android/iOS, ícones, assinatura, envio às lojas                                                    | —                          | planejada |

## Pós-lançamento (do GDD)

Evoluções por item, vínculo, horário, zona e troca; criação (breeding) e herança de Genes; Prismáticos (1/2048) e eventos sazonais; PvP assíncrono e ranking; torre de batalhas / modo roguelike; apostas com moeda do jogo; batalha automática e velocidade 2x; trocas entre jogadores; conquistas e missões diárias; monetização sem pay-to-win (anúncio recompensado, passe cosmético, remover anúncios, skins).

## Decisões globais já tomadas

| Decisão                                                                 | Motivo                                                                  |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| O jogo é só online; não há modo offline                                 | Decisão do dono. Substitui o "save local criptografado" do GDD          |
| O servidor é a autoridade das regras (stats, dano, captura, recompensas) | Evita trapaça e é pré-requisito de PvP e trocas                         |
| As telas chamam serviços com `await`, que falam com a API               | As telas não mudam quando uma regra muda no servidor                    |
| O catálogo é modelado como tabelas relacionais desde o JSON estático   | O banco do backend nasce quase igual aos arquivos de `res://data/`      |
| Monorepo: o jogo em `client/` e o servidor em `server/`                | Contrato da API e cliente mudam no mesmo commit; as specs ficam num lugar só. O Render publica só a pasta `server/` |
| Backend em **NestJS** (TypeScript), com **Prisma** como ORM              | Estrutura em módulos e DTOs validados; Prisma é o ORM mais simples de começar |
| **Supabase** só como infraestrutura: Postgres, Auth e Storage           | Postgres gerenciado; Auth já faz Google e Apple; Storage serve sprites e catálogo |
| O Godot conversa **só com o NestJS**; nunca com o banco nem com a API automática do Supabase | Com o servidor como autoridade, o cliente não pode gravar estado; o Supabase publica o schema `public` na API automática, então as tabelas ficam com RLS ligado e sem regras (ou num schema não publicado) |
| O login é feito no Supabase Auth; o NestJS confere o token (JWT pelas chaves públicas do Supabase) | O token prova quem é o jogador sem o NestJS depender do SDK do Supabase nas regras |
| As regras de jogo do servidor ficam num pacote TypeScript puro (sem Nest, sem banco), com testes | Espelha `res://domain/`; fórmula errada no servidor vira bug para todos, então ali há testes |
| O contrato entre cliente e servidor é a API (OpenAPI gerado pelo Nest)  | O Godot não lê tipos TypeScript; o `ApiGameService` a chama sem que as telas saibam |

## Dúvidas globais em aberto

- **Backend, o que falta decidir:** a stack está nas decisões acima. Ficam para o planejamento do `backend-api`: hospedagem do NestJS (candidato: Render, na mesma região do Supabase), quem é o dono do catálogo (decidido: o banco; o cliente baixa pela API com a `HttpDataSource`) e o plano do Supabase para produção (o grátis pausa o projeto depois de uma semana sem uso).
- **Nível do Domador:** o Hub mostra o nível, mas o GDD não diz como ele sobe. No MVP fica fixo em 1.
- **Curva Erratic:** citada no GDD sem fórmula. Fora do catálogo até ser definida.
- **Estilo de arte:** as telas usam placeholders (forma na cor do elemento) até existir arte das 3 linhas iniciais.
- **Tradução:** textos em pt-BR direto nas cenas e scripts (decisão do MVP). Se o jogo for traduzido, os textos migram para o sistema de tradução do Godot e o catálogo ganha tabelas de nomes por idioma.
- **Nome e marca:** checar "Ecobeast" no INPI, USPTO/EUIPO, lojas e domínio antes do lançamento (GDD, "Próximos passos").
