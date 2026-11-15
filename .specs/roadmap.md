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
| 8   | [`npc-tamers`](npc-tamers/) | Domadores NPC sorteados no mapa de Explorar zona, com fala, luta obrigatória de 1×1, 2×2 ou 3×3 e recompensa maior, e o Desafiar do Hub contra um Domador sorteado | board-battle, biome-encounters, progression | concluída |
| 8b  | `npc-fixed-teams`   | Domadores NPC com nome e equipe fixa, montados à mão na tabela `npc_tamers`                               | npc-tamers                 | planejada |
| 8c  | [`battle-intro`](battle-intro/) | A abertura da luta: transição de zoom pixelado e música retrô original, uma para selvagem e outra para Domador, com toque de vitória | board-battle, npc-tamers | concluída |
| 9   | [`team-and-storage`](team-and-storage/) | Equipe com 6 vagas reorganizáveis, Santuário com busca e filtro (TELAS.md #9 e #10) e troca de Ecobeast durante a luta | capture                    | concluída |
| 10  | [`creature-details`](creature-details/) | Tela de detalhes da criatura (TELAS.md #8); vem antes do `battle-core`, por decisão do dono | auth-google                | concluída |
| 11  | [`inventory-shop`](inventory-shop/) | Mochila e Loja (TELAS.md #12 e #13); tabelas `items`, `item_categories`, `inventory_items`; usar itens no mapa e na luta | backend-api, battle-screen, wild-battle | concluída |
| 13  | [`codex`](codex/) | Bestiário com visto/capturado, detalhe e linha evolutiva (TELAS.md #11), e o aviso de registro na primeira captura e na Evolução | npc-tamers, progression, capture | concluída |
| 14  | `arenas-league`     | 8 Arenas, emblemas, Liga final e desbloqueio secreto do Ancestral (TELAS.md #15)                          | npc-tamers                 | planejada |
| 15  | `profile-settings`  | Perfil com estatísticas e configurações (TELAS.md #16)                                                    | auth-google                | planejada |
| 16  | `content`           | 60–90 espécies, ~80 técnicas, ~20 traços, balanceamento                                                   | progression                | planejada |
| 17  | `release-pipeline`  | Export Android/iOS, ícones, assinatura, envio às lojas                                                    | —                          | planejada |
| 18  | `audio`             | Introdução dos sons do jogo, com o som de cura do Refúgio entre os primeiros. A música da luta veio antes, na `battle-intro` | heal-station               | planejada |
| 19  | [`content-viewer`](content-viewer/) | Janela só de desenvolvimento, aberta com F1 pelo editor, com Ecobeasts, Técnicas, Elementos, biomas, itens, Traços, Temperamentos e Estados, e os arquivos que faltam de cada um | board-battle | concluída |
| 20  | [`hidden-traits`](hidden-traits/) | 1 chance em 20 de um Ecobeast (inicial ou selvagem) nascer com o Traço oculto da espécie | auth-google | concluída |
| 21  | [`creature-sounds`](creature-sounds/) | O som característico de cada Ecobeast: o lugar do `call.wav` e o visualizador; tocar no jogo fica para depois | content-viewer | concluída |
| 22  | [`map-editor`](map-editor/) | Editor de ilhas só de desenvolvimento (F2, 16:9): terreno do zero ou pelo gerador, construções, áreas de Ecobeasts com nível fixo, rascunho e publicar | content-viewer, biome-encounters | concluída |
| 23  | [`islands`](islands/) | Ilhas fixas no jogo: a lista de ilhas no Hub, andar na ilha publicada, as construções abrindo as telas delas e os Ecobeasts nascendo pelas áreas | map-editor                 | concluída |
| 24  | [`legacy-battle-removal`](legacy-battle-removal/) | Apagar a luta antiga, que nenhuma tela abria desde a board-battle/05: a tela `battle`, as rotas `/v1/me/battle` e o laço de turno antigo, com os testes das regras compartilhadas portados para a luta no tabuleiro | board-battle | concluída |
| 25  | [`terrain-height`](terrain-height/) | A altura do terreno em cada hexágono, de 0 a 10 (de 0 a 4 até a 02), em qualquer bioma; Colina e Montanha viram biomas, e o editor ganha a ferramenta Altura no lugar da Forma; a 03 deixa ver o que a altura esconde, no editor e no jogo | map-editor, islands | concluída |
| 26  | [`island-villages`](island-villages/) | Vilas nas ilhas: trilhas e pisos, objetos de 1 a 4 hexágonos com variante, espelho e bloqueio, e as construções viradas ações | terrain-height, islands | concluída |
| 27  | [`free-props`](free-props/) | Arte livre nas ilhas: peças soltas em pixels, só enfeite, e carimbos que viram objetos, peças e chão; a ferramenta única Peças no editor; a 05 traz de volta as decorações naturais, com a Borracha | island-villages | concluída |
| 28  | [`free-trails`](free-trails/) | Caminhos nas ilhas: 4 tipos novos de chão, a máscara de chão com borda irregular e emendas entre tipos, e os traços livres desenhados pela ferramenta Caminho | free-props | concluída |
| 29  | [`vegetation-brush`](vegetation-brush/) | Só 6 objetos de grade ficam (as casas, os prédios do Refúgio e da Loja e a cerca da cidade), e o editor ganha a ferramenta Vegetação, um pincel que espalha peças soltas por grupo | free-trails | concluída |
| 30  | [`tamer-appearance`](tamer-appearance/) | A aparência do Domador em camadas (boneca de papel): corpo masculino ou feminino, pele, rosto, cabelo, chapéu e roupas, cada peça com a cor da paleta, e a tela Aparência na entrada e pelo avatar do Hub | auth-google, islands | concluída |
| 31  | [`free-fences`](free-fences/) | A cerca vira parede: um traço em qualquer ângulo (madeira, pedra ou invisível), desenhado pela ferramenta Cerca do editor, que bloqueia o Domador pela linha exata; as cercas de grade viram paredes, e a Cerca (cidade) sai | free-trails, vegetation-brush | concluída |
| 32  | [`camera-zoom`](camera-zoom/) | O zoom da câmera em pinça: ao explorar, em degraus inteiros de pixel art com o Domador no centro e guardado no aparelho; na luta, contínuo até 2,5 vezes o tabuleiro inteiro, com a vista arrastável; a roda do mouse no PC | wild-battle, islands, board-battle | concluída |
| 33  | [`skill-cooldown`](skill-cooldown/) | Countdown por Técnica, em rodadas, além do PP, respeitado pelo jogador e pela IA; 3 Técnicas por Ecobeast; na luta, a barra de 3 ícones com o detalhe ao segurar | board-battle, progression | concluída |
| 34  | [`skill-editor`](skill-editor/) | Editar e criar Técnicas no visualizador (F1): o botão Editar, o formulário com campos, efeitos e quem aprende, as rotas do editor que conferem com as regras do jogo e gravam numa transação, e o alvo "Meu time" | content-viewer, map-editor, skill-cooldown | concluída |
| 35  | [`free-objects`](free-objects/) | Os objetos de grade viram peças soltas, e toda peça pode bloquear por linhas, como a cerca: o bloqueio é do tipo, ajustável por peça e editável ponto a ponto no editor; a ação é do prédio, ao encostar; o servidor conta como bloqueado todo hexágono que um bloqueio ou uma parede toca | free-props, free-fences, island-villages | concluída |
| 36  | [`vegetation-packs`](vegetation-packs/) | 33 tipos novos de peça solta com a arte de três pacotes da craftpix.net (12 árvores, 13 arbustos e 8 pedras, com os tamanhos como variantes) e 6 grupos novos no pincel Vegetação; as decorações do bioma e o mapa sorteado não mudam | free-objects, vegetation-brush | concluída (falta o dono usar) |
| 37  | [`prop-depth-blocks`](prop-depth-blocks/) | Peças, decorações e atores na ordem do pé, também entre linhas de hexágonos; o bloqueio padrão por variante, com as pedras e árvores grandes dos pacotes já bloqueando; o hexágono bloqueado só quando a linha pega o centro; e a ferramenta Bloqueios do editor | free-objects, vegetation-packs | concluída (falta o dono conferir) |
| 38  | [`vegetation-wind`](vegetation-wind/) | Os arbustos dos pacotes balançam com o vento das decorações do bioma, e os pixels da copa das árvores mexem pelo ruído do vento | vegetation-packs | concluída (falta o dono conferir) |
| 39  | [`bridges`](bridges/) | Pontes retas em qualquer ângulo, desenhadas no editor com a arte de um pacote da craftpix.net; a água passa a bloquear nas ilhas e no mapa sorteado, e a ponte é o corredor para atravessar | free-fences, prop-depth-blocks | concluída (falta o dono conferir) |
| 40  | [`desert-snow`](desert-snow/) | Os biomas Deserto e Neve: no catálogo, com quem nasce neles; no mapa sorteado, pelo ruído de temperatura, nas pontas quente e fria; e no editor, com o chão, os arremates, o escorrido e as decorações gerados por script | terrain-height, biome-encounters | concluída (falta o dono conferir) |
| 41  | [`fence-art`](fence-art/) | A cerca de madeira e o muro de pedra ganham a arte do pacote Sunnyside World (postes de topo redondo, pilares), com a travessa vista de cima nos trechos acima de 60°; o traço, o bloqueio e o editor não mudam | free-fences | concluída (falta o dono conferir) |
| 42  | [`nature-variety`](nature-variety/) | Mais natureza em cada bioma: 24 tipos novos de decoração no estilo de hoje (bétula, carvalho, abeto, galhos, troncos, tocos, cogumelos, mato alto, flores, trevo, cardo, lajes, rolo seco, cristais de gelo e outros), gerados pelo `make_nature.py` e sorteados no fim da receita, sem mudar as decorações de antes; nas ilhas, nenhuma decoração nasce em cima de uma peça; e os tipos novos e os do Deserto e da Neve viram peças soltas, com os grupos do pincel | desert-snow, vegetation-brush | concluída (falta o dono conferir) |
| 43  | [`home-pack`](home-pack/) | A casa grande do pacote Main Characters Home vira a peça 95, com a fumaça da chaminé em 6 quadros trocados no shader, mais a Casa pequena (96) e o Sobrado pequeno (97), remontados com os pixels dela, os três em 8 cores, e a cerca de estacas do mesmo pacote vira o tipo de parede 4, com uma estaca a cada 8 px e o trecho em pé do pacote acima de 60° | free-objects, fence-art | concluída (falta o dono conferir) |

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
- **Renda de moedas:** o selvagem paga pouco ao ser derrotado e tira um pouco ao vencer ([progression/05](progression/05-wild-coins.md)), e os Domadores NPC pagam três vezes mais ([npc-tamers](npc-tamers/architecture.md#luta-contra-domador)). Faltam os outros cenários de ganho.
- **Nomes dos próximos itens:** os itens do GDD que ainda não entraram no catálogo passam pela mesma revisão de nomes da [inventory-shop](inventory-shop/) antes de serem criados.
- **Nível do Domador:** o Hub mostra o nível, mas o GDD não diz como ele sobe. No MVP fica fixo em 1.
- **Curva Erratic:** citada no GDD sem fórmula. Fora do catálogo até ser definida.
- **Estilo de arte:** as telas usam placeholders (forma na cor do elemento) até existir arte das 3 linhas iniciais.
- **Tradução:** textos em pt-BR direto nas cenas e scripts (decisão do MVP). Se o jogo for traduzido, os textos migram para o sistema de tradução do Godot e o catálogo ganha tabelas de nomes por idioma.
- **Licença dos sprites de terreno:** confirmar se o pacote usado na [wild-battle](wild-battle/) permite uso comercial antes do lançamento.
- **Nome e marca:** checar "Ecobeast" no INPI, USPTO/EUIPO, lojas e domínio antes do lançamento (GDD, "Próximos passos").
