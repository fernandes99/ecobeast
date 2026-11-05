# Roadmap

O que vem depois do MVP de estrutura (entrada, escolha do inicial e Hub). Cada linha vira uma iniciativa em `.specs/<nome>/` quando for planejada; até lá, o status é `planejada` e o escopo é só a frase abaixo. A ordem é a sugerida, não um compromisso.

## Iniciativas do jogo 1.0

| #   | Iniciativa          | Entrega                                                                                                   | Depende de                 | Status    |
| --- | ------------------- | --------------------------------------------------------------------------------------------------------- | -------------------------- | --------- |
| 1   | [`backend-api`](backend-api/) | Banco no Supabase (todas as tabelas num `schema.prisma`), API NestJS de leitura do catálogo com docs Scalar; o jogo passa a ler o catálogo da API | MVP                        | concluída |
| 1b  | [`visual-theme`](visual-theme/) | Paleta escura em todo o jogo e o Hub no layout do protótipo do dono, com espaços para as ilustrações | MVP                        | concluída |
| 2   | [`auth-google`](auth-google/) | Login com Google pelo navegador (Supabase Auth via NestJS); o jogador passa a viver no servidor: criar Domador, escolher inicial e apagar progresso viram rotas do NestJS. Login nativo e "Entrar com a Apple" ficam para depois | backend-api                | concluída    |
| 3   | [`battle-core`](battle-core/) | Máquina de estados da batalha, dano, ordem do turno, status, IA simples — autoridade no servidor | auth-google                | concluída |
| 4   | [`battle-screen`](battle-screen/) | Tela de batalha (TELAS.md #5) ouvindo os eventos do battle-core, com encontro sorteado pelo servidor | battle-core                | concluída |
| 4b  | [`heal-station`](heal-station/) | Refúgio: curar HP, PP e status da equipe (TELAS.md #14); vem logo depois da tela de batalha, porque a luta mantém HP e PP e uma derrota total impede lutar de novo | battle-core                | concluída |
| 5   | [`wild-battle`](wild-battle/) | Mapa hexagonal gerado a cada exploração, com o jogador andando por ele; substitui a seleção de zonas (TELAS.md #4) | battle-screen, heal-station | concluída |
| 5b  | [`biome-encounters`](biome-encounters/) | Ecobeasts nascem no mapa por taxa de bioma, e Procurar enfrenta um do hexágono do Domador | wild-battle, capture       | concluída |
| 5c  | `hidden-encounters` | Encontro escondido ao andar, sem ver o Ecobeast antes                                                     | biome-encounters           | planejada |
| 5d  | `biome-terrain`     | O bioma do hexágono decide o Campo; regiões fundas de água e montanha só com Ecobeasts que voem ou nadem  | biome-encounters           | planejada |
| 6   | [`capture`](capture/) | Esferas de Vínculo, fórmula de captura e o carregamento do Ecobeast entrando na Esfera (TELAS.md #6); o capturado vai para a equipe de 6 ou para o Santuário | wild-battle, inventory-shop | concluída |
| 7   | [`progression`](progression/) | XP dividido entre quem lutou, subir de nível, aprender/esquecer Técnica e Evolução por nível, que pode ser cancelada (TELAS.md #7), e moedas contra o selvagem | battle-core, team-and-storage | concluída |
| 7b  | [`battle-slots`](battle-slots/) | Lutas de até 3 contra 3 no motor e na tela (por enquanto, toda luta de verdade é 1 contra 1), e a cena da batalha dos mockups do dono. Substituída pela luta no tabuleiro; só o motor foi feito | progression | substituída |
| 7c  | [`board-battle`](board-battle/) | A luta num tabuleiro de hexágonos: fila por Velocidade, andar e agir na vez, Técnicas com alcance, forma e marca no chão; substitui a luta de Explorar zona | progression, battle-slots | concluída |
| 8   | `npc-tamers`        | Domadores NPC com equipe fixa e recompensa em moedas; tabela `npc_tamers`                                 | battle-screen              | planejada |
| 9   | [`team-and-storage`](team-and-storage/) | Equipe com 6 vagas reorganizáveis, Santuário com busca e filtro (TELAS.md #9 e #10) e troca de Ecobeast durante a luta | capture                    | concluída |
| 10  | [`creature-details`](creature-details/) | Tela de detalhes da criatura (TELAS.md #8); vem antes do `battle-core`, por decisão do dono | auth-google                | concluída |
| 11  | [`inventory-shop`](inventory-shop/) | Mochila e Loja (TELAS.md #12 e #13); tabelas `items`, `item_categories`, `inventory_items`; usar itens no mapa e na luta | backend-api, battle-screen, wild-battle | concluída |
| 13  | `codex`             | Bestiário com visto/capturado, detalhe e linha evolutiva (TELAS.md #11)                                   | wild-battle                | planejada |
| 14  | `arenas-league`     | 8 Arenas, emblemas, Liga final e desbloqueio secreto do Ancestral (TELAS.md #15)                          | npc-tamers                 | planejada |
| 15  | `profile-settings`  | Perfil com estatísticas e configurações (TELAS.md #16)                                                    | auth-google                | planejada |
| 16  | `content`           | 60–90 espécies, ~80 técnicas, ~20 traços, balanceamento                                                   | progression                | planejada |
| 17  | `release-pipeline`  | Export Android/iOS, ícones, assinatura, envio às lojas                                                    | —                          | planejada |
| 18  | `audio`             | Introdução dos sons do jogo, com o som de cura do Refúgio entre os primeiros                              | heal-station               | planejada |

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
- **Fuga:** a chance fixa de 20% de falhar é provisória. Rever, talvez com um cálculo a partir do inimigo ([battle-core](battle-core/README.md)).
- **Abandonar batalha:** fechar o app no meio da luta escapa de uma derrota e devolve a Esfera de uma captura que falhou. Aceito por enquanto; rever quando a batalha for guardada no banco.
- **Preço do Refúgio:** a cura é de graça por enquanto, e o dono quer cobrar moedas depois. Falta definir o valor e o que acontece com quem não tem moedas, para não prender o jogador depois de uma derrota.
- **Renda de moedas:** o selvagem paga pouco ao ser derrotado e tira um pouco ao vencer ([progression/05](progression/05-wild-coins.md)), e quem vai pagar bem são os Domadores NPC. Faltam os valores deles e os outros cenários de ganho.
- **Nomes dos próximos itens:** os itens do GDD que ainda não entraram no catálogo passam pela mesma revisão de nomes da [inventory-shop](inventory-shop/) antes de serem criados.
- **Nível do Domador:** o Hub mostra o nível, mas o GDD não diz como ele sobe. No MVP fica fixo em 1.
- **Curva Erratic:** citada no GDD sem fórmula. Fora do catálogo até ser definida.
- **Estilo de arte:** as telas usam placeholders (forma na cor do elemento) até existir arte das 3 linhas iniciais.
- **Tradução:** textos em pt-BR direto nas cenas e scripts (decisão do MVP). Se o jogo for traduzido, os textos migram para o sistema de tradução do Godot e o catálogo ganha tabelas de nomes por idioma.
- **Licença dos sprites de terreno:** confirmar se o pacote usado na [wild-battle](wild-battle/) permite uso comercial antes do lançamento.
- **Nome e marca:** checar "Ecobeast" no INPI, USPTO/EUIPO, lojas e domínio antes do lançamento (GDD, "Próximos passos").
