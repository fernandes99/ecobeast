# Specs

Entregas grandes começam por uma spec escrita aqui, antes do código. A spec é o que a pessoa (ou a IA) que vai implementar lê para saber o que fazer, onde e como conferir que ficou pronto.

O Ecobeast é um jogo mobile (Android/iOS, retrato): o cliente em **Godot 4.7 com GDScript** (`client/`) e a API em NestJS (`server/`), no mesmo repositório. O design do jogo está em `GDD.md` e a lista de telas em `TELAS.md`, na raiz do repositório. As specs transformam esses documentos em entregas implementáveis; quando uma spec e o GDD divergem, vale a spec (e o GDD é atualizado).

## Organização

- Uma pasta por iniciativa, com nome em inglês e kebab-case: `.specs/<iniciativa>/`.
- `README.md` da iniciativa: contexto, objetivos, decisões, fora do escopo, pré-requisitos e a tabela de fases com o status de cada uma.
- `architecture.md` (opcional): o desenho técnico que mais de uma fase compartilha.
- Uma spec por fase, numerada na ordem de implementação: `01-<assunto>.md`, `02-<assunto>.md`. Cada fase tem o tamanho de uma entrega que dá para commitar e validar sozinha.
- Arquivos da raiz: este `README.md`, o [glossary.md](glossary.md) (vocabulário do jogo e nomes no código) e o [roadmap.md](roadmap.md) (iniciativas futuras e dúvidas globais).

## Iniciativas

| Iniciativa                  | Assunto                                                                                  |
| --------------------------- | ---------------------------------------------------------------------------------------- |
| [foundation](foundation/)   | Esqueleto do projeto Godot: pastas, camadas, configurações, tema, navegação e componentes |
| [game-data](game-data/)     | Modelo relacional do catálogo em JSON estático, camada de dados e conteúdo inicial        |
| [onboarding](onboarding/)   | Tela de entrada com o nome do Domador e escolha do Ecobeast inicial                      |
| [hub](hub/)                 | Tela principal com a equipe e o acesso a todas as features do jogo                       |
| [backend-api](backend-api/) | Servidor: banco no Supabase, API NestJS do catálogo e o jogo lendo o catálogo dela        |
| [visual-theme](visual-theme/) | Paleta escura em todo o jogo e o Hub no layout do protótipo                            |
| [auth-google](auth-google/) | Login com Google pelo navegador e o jogador morando no servidor                          |
| [creature-details](creature-details/) | Tela de detalhes do Ecobeast, com atributos, Genes, Técnicas e apelido         |
| [battle-core](battle-core/) | O juiz da batalha no servidor: regras, turno, status, IA e API                           |
| [battle-screen](battle-screen/) | A tela de batalha no jogo, com encontro sorteado pelo servidor                     |
| [heal-station](heal-station/) | O Refúgio: tela e rota que curam a equipe                                                |
| [wild-battle](wild-battle/) | Mapa hexagonal gerado a cada exploração, com o jogador andando por ele                    |
| [inventory-shop](inventory-shop/) | Loja, Mochila e o uso de itens no mapa e na luta                                   |
| [capture](capture/)         | Usar Esferas na luta para capturar Ecobeasts, com o carregamento na tela                  |
| [team-and-storage](team-and-storage/) | Equipe, Santuário e troca de Ecobeast durante a luta                           |
| [biome-encounters](biome-encounters/) | Ecobeasts nascendo no mapa, por taxa de bioma, e encontro pelo hexágono        |
| [progression](progression/) | XP e moedas depois da luta, subir de nível, Técnicas novas e Evolução                   |
| [battle-slots](battle-slots/) | Vários Ecobeasts por lado no motor da luta (substituída pela board-battle)           |
| [board-battle](board-battle/) | A luta num tabuleiro de hexágonos, com fila, andar, alcance e marcas no chão         |
| [content-viewer](content-viewer/) | Janela de desenvolvimento (F1) com todo o conteúdo do jogo e os arquivos que faltam |
| [hidden-traits](hidden-traits/) | 1 chance em 20 de um Ecobeast nascer com o Traço oculto da espécie |
| [creature-sounds](creature-sounds/) | O som característico de cada Ecobeast (`call.wav`), por enquanto só no visualizador |
| [npc-tamers](npc-tamers/) | Domadores NPC sorteados no mapa e no Desafiar do Hub, com fala e luta obrigatória |
| [codex](codex/) | Bestiário: espécies vistas em luta e capturadas, detalhe com linha evolutiva e o aviso de registro |
| [battle-intro](battle-intro/) | A abertura da luta: zoom pixelado e música retrô de selvagem, de Domador e de vitória |
| [map-editor](map-editor/) | Editor de ilhas só de desenvolvimento (F2): terreno, construções, áreas de Ecobeasts, rascunho e publicar |
| [islands](islands/) | Jogar nas ilhas publicadas: a lista no Hub, as construções abrindo as telas e os Ecobeasts pelas áreas |
| [legacy-battle-removal](legacy-battle-removal/) | A luta antiga apagada do servidor e do jogo, com os testes das regras portados |
| [island-villages](island-villages/) | Vilas nas ilhas: trilhas e pisos, objetos com bloqueio e as construções viradas ações |
| [town-art](town-art/) | O estilo de arte das cidades, com guia: Refúgio, Loja e Arena reconhecíveis, casas e objetos da cidade como tipos novos e decorações de rua |
| [terrain-height](terrain-height/) | A altura do terreno em cada hexágono, Colina e Montanha como biomas e a ferramenta Altura no editor |
| [free-props](free-props/) | Arte livre nas ilhas: peças soltas em pixels, carimbos, a ferramenta Peças e a Borracha |
| [free-trails](free-trails/) | Caminhos nas ilhas: tipos novos de chão, emendas naturais entre eles e traços livres desenhados no editor |
| [vegetation-brush](vegetation-brush/) | A limpeza dos objetos de grade e o pincel de vegetação do editor |
| [island-npcs](island-npcs/) | NPCs nas ilhas: o catálogo, a ferramenta NPC do editor, o passeio, a conversa e a ação |
| [water-motion](water-motion/) | A água se mexendo e as cachoeiras nas laterais da água alta, com espuma no pé |
| [free-fences](free-fences/) | Cercas livres nas ilhas: traços em qualquer ângulo que são parede, a parede invisível e o fim da cerca de grade |
| [tamer-appearance](tamer-appearance/) | A aparência do Domador em camadas: corpo, pele, rosto, cabelo, chapéu e roupas, com a cor por paleta e a tela Aparência |
| [camera-zoom](camera-zoom/) | O zoom da câmera em pinça ao explorar e na luta, entre um mínimo e um máximo |
| [skill-cooldown](skill-cooldown/) | Countdown por Técnica, 3 Técnicas por Ecobeast e a barra de ícones na luta |
| [skill-editor](skill-editor/) | Editar e criar Técnicas no F1, com os efeitos e quem aprende, salvas pelo servidor |
| [free-objects](free-objects/) | Os objetos de grade viram peças soltas que bloqueiam por linhas, editáveis no editor, com a ação do prédio ao encostar |
| [vegetation-packs](vegetation-packs/) | As árvores, os arbustos e as pedras de três pacotes da craftpix.net como peças soltas, na ferramenta Peças e no pincel Vegetação |
| [prop-depth-blocks](prop-depth-blocks/) | A ordem de desenho pelo pé, o bloqueio padrão por variante, o hexágono bloqueado pelo centro e a ferramenta Bloqueios do editor |
| [vegetation-wind](vegetation-wind/) | Os arbustos dos pacotes balançando com o vento das decorações do bioma e os pixels da copa das árvores mexendo no vento |
| [bridges](bridges/) | Pontes retas em qualquer ângulo nas ilhas, com a arte de um pacote, e a água bloqueando o andar |
| [desert-snow](desert-snow/) | Os biomas Deserto e Neve no catálogo, no mapa sorteado, nas ilhas e na luta, com o chão, os arremates e as decorações |
| [fence-art](fence-art/) | A cerca de madeira e o muro de pedra com a arte do pacote Sunnyside World, com a travessa vista de cima nos trechos em pé |
| [nature-variety](nature-variety/) | 24 tipos novos de decoração (árvores, galhos, troncos, mato, flores, cogumelos e pedras) no sorteio de cada bioma e como peças soltas |
| [home-pack](home-pack/) | A casa grande do pacote Main Characters Home, com a fumaça da chaminé animada, a pequena e o sobrado pequeno, em 8 cores, e a cerca de estacas do mesmo pacote |
| [coast-rivers](coast-rivers/) | O mar num lado do mapa, a Praia, os lagos, os rios e as travessias (pontes automáticas e vaus) |
| [day-night](day-night/) | O relógio do mundo (um dia em 24 minutos), a luz da hora no mapa e na luta, o indicador da parte do dia e as luzes da noite |
| [fireflies](fireflies/) | Vagalumes à noite na Planície e no Boreal, desenhados e iluminando pelo shader da noite |
| [day-phase-spawns](day-phase-spawns/) | As partes do dia em que cada Ecobeast nasce (`species_day_phases`) e o sorteio dos selvagens pela hora da entrada |
| [puffcoo-line](puffcoo-line/) | Puffcoo e Galecrest, a linha de Vento, com o estado Atordoado, as marcas que baixam atributos e as Técnicas que mexem no campo |
| [fog-of-war](fog-of-war/) | A névoa no mapa de Explorar: só o que o Domador descobriu aparece, e nas ilhas a descoberta fica guardada na conta |
| [minimap](minimap/) | O minimapa redondo e dourado de Explorar e o mapa grande da ilha, com o descoberto, o Domador e os ícones do Refúgio, da Loja e dos NPCs |
| [timber-house](timber-house/) | A casa enxaimel do pacote Glassblower's Workshop, montada pelos tiles dele, em 8 cores, com a fumaça e as luzes das janelas |
| [story](story/) | As cenas da história: o roteiro no cliente, os Marcos do jogador no servidor, a ferramenta Cenas do F2 e a Linha da história |
| [browt-line](browt-line/) | O inicial de Flora refeito: Browt, Eagrow e Sowingle, com 4 Técnicas físicas e a marca Espinheiro |
| [stone-cottage](stone-cottage/) | A casinha de pedra da imagem do dono, como peça solta em 8 cores |
| [home-island](home-island/) | Liora como a casa do jogador: o app abre nela, o Hub vira o menu do Domador e as viagens saem da ação Viagem |
| [liora-intro](liora-intro/) | A introdução em Liora: o Domador sem nome, os NPCs pessoas, a criação por cima do mapa, o inicial numa cena e as cenas do roteiro |
| [timber-cottage](timber-cottage/) | A casinha enxaimel da imagem do dono, como peça solta em 8 cores |
| [chimney-smoke](chimney-smoke/) | A casa com chaminé pode ficar sem a fumaça, peça por peça, escolhida no editor |
| [editor-performance](editor-performance/) | O editor de ilhas sem travar numa ilha cheia, e o botão que para as animações do mapa nele |
| [dialogue-voices](dialogue-voices/) | As falas com voz: um bipe retrô enquanto o texto aparece, uma voz por personagem, escolhida no F2 |
| [refuge-art](refuge-art/) | O prédio do Refúgio com a arte da imagem do dono, no padrão das casas: 8 cores, fumaça e luzes |
| [interiors](interiors/) | O lado de dentro dos prédios: a sala de quadrados com o tileset do Main Characters Home, o Domador andando e falando com os NPCs lá dentro, e o modo Interiores do F2 |
| [village-crowd](village-crowd/) | Os moradores genéricos da vila, para o dono pôr passeando no F2, cada um com uma fala padrão |
| [seedlet-line](seedlet-line/) | O inicial de Flora com a arte nova e outros nomes: Seedlet, Grovequill e Arbornix, nos ids do Browt, do Eagrow e do Sowingle |
| [tidebud-line](tidebud-line/) | O cavalo-marinho de folhas e raios, a primeira linha de Volt: Tidebud, Kelpcoil e Tempestide, com as primeiras Técnicas de Volt e a marca Maré Elétrica |
| [portal-altar](portal-altar/) | O altar-portal do Veilmoth, a mariposa arcana que teleporta, como peça solta com e sem a mariposa |
| [field-effects](field-effects/) | Os estados Preso (no tabuleiro), Encharcado e Brotando, a marca que cura e mais seis marcas, com dez Técnicas novas |
| [biome-zones](biome-zones/) | As zonas dos biomas (Bosque, Arbustal, Clareira e outras), com plantas próprias e, no mapa sorteado, quem nasce em cada uma; nas ilhas, pintadas pela ferramenta Zona do F2 |
| [board-size](board-size/) | O tabuleiro da luta com o tamanho sorteado a cada luta, conforme o formato, os lados começando perto do meio e a pinça num campo de qualquer tamanho |
| [village-pack](village-pack/) | As casas, os objetos e as cercas do tileset Village do Fantasy Dreamland Reborn: 10 casas em 8 cores, 17 objetos, as placas do Refúgio e da Loja e 2 paredes |
| [editor-ui](editor-ui/) | O F2 mais fácil: as peças em 13 categorias, com busca e grade de miniaturas, e o topo que cabe na janela |
| [prop-cleanup](prop-cleanup/) | Peças que o dono não quer mais saem do catálogo, das ilhas e da arte: o poste, a placa, o prédio da Loja, as casas da cidade e o Observatório |
| [status-descriptions](status-descriptions/) | Cada estado da luta ganha a descrição do que faz, com os números das regras, vista no F1 |
| [item-icons](item-icons/) | O padrão dos ícones dos itens (pixel art de 32×32, mostrada em múltiplos inteiros) os Tônicos e o Bálsamo Puro com a arte de um pacote da craftpix.net e as Esferas em pixel art |
| [lume-line](lume-line/) | A coruja da noite, a primeira linha de Sombra pura: Lume, Owlume e Noclume (Sombra/Psíquico), que só nascem à Noite, com 4 Técnicas de Sombra especiais |
| [creature-scale](creature-scale/) | Os Ecobeasts maiores em Explorar: a altura de hoje mais 4 pixels, de 6 a 32, com a pixel art no acabamento do pacote Fantasy Dreamland Reborn |
| [creature-fronts](creature-fronts/) | A arte nova do dono no `front.png` das linhas do Ruvo, da Nilu, do Clod e do Hushling, e o `board.png` refeito dela |
| [snekit-line](snekit-line/) | A serpente Snekit e Venomaw, a primeira linha com Toxina, que evolui por Vínculo mais o nível 32 |
| [prayling-line](prayling-line/) | O louva-a-deus, a primeira linha de Inseto: Prayling e Mantorn, que evolui no Solantis (Inseto/Luz) de dia ou no Umbrantis (Inseto/Sombra) à noite, com a evolução por horário no servidor e as primeiras Técnicas de Inseto e de Luz |
| [bond](bond/) | O Vínculo do Domador com cada Ecobeast, e a evolução por Vínculo |
| [map-realism](map-realism/) | O mapa sorteado com um clima por mapa, a Neve longe da Planície e do Deserto, um relevo só e sem o Vau |
| [skill-test](skill-test/) | O Testar técnica do F1: uma luta de verdade com um Ecobeast emprestado, o oponente escolhido e nada gravado |
| [debug-panels](debug-panels/) | O Debug de Explorar e o F3 da luta organizados em abas |
| [giant-rocks](giant-rocks/) | As pedras gigantes da Montanha, como peças do F2 e sorteadas nas Montanhas do mapa sorteado, bloqueando pelo pé |
| [sea-life](sea-life/) | As algas, as pedras e o lixo da Água rasa e da profunda, na Comum e em zonas (Algal, Pedras rasas, Floresta de algas, Rochedo e Lixo), e como peças do F2 |
| [beach-life](beach-life/) | Os coqueiros na Praia, na Comum e na zona Coqueiral, e como peças do F2 |
| [sandlurk-line](sandlurk-line/) | O escorpião enterrado, Sandlurk e Dunestrike (Inseto/Toxina), um tanque lento do Deserto e da Praia, com 4 Técnicas de escorpião |
| [hopling-line](hopling-line/) | A canguru médica, Hopling e Pouchmend (Instinto), o primeiro Ecobeast de suporte, com 4 Técnicas que curam e protegem os aliados |
| [terrain-plateaus](terrain-plateaus/) | O relevo do mapa sorteado em patamares, com paredões que bloqueiam o Domador em todo mapa, escadarias e a Montanha de 8 a 10 |
| [glimshell-line](glimshell-line/) | O jabuti de cristal, Glimshell, Lumoshell e Prismback (Luz), o primeiro tanque especial, com 4 Técnicas de Luz que protegem e enfraquecem |
| [veilmoth-line](veilmoth-line/) | A mariposa gêmea, Veilmoth e Gatemoth (Arcano), Épica e só da Noite, com as primeiras Técnicas de Arcano e o Teleporte, que leva qualquer Ecobeast do campo a um hexágono vazio |
| [hub-start](hub-start/) | O início sem história: criar o Domador, escolher o inicial e o Hub com a equipe, o Ecobeast em destaque, o Explorar no mapa gerado, a tela Ecobeasts, o Perfil e as Configurações |
| [rolling-hills](rolling-hills/) | A Colina e a Montanha sorteadas separadas no mapa sorteado: morros soltos de 1 ou 2 níveis e montanhas em maciços, com ou sem sopé |
| [creature-faces](creature-faces/) | O rosto de cada Ecobeast, recortado do front por um script, num círculo com a cor do Elemento e o anel de HP em volta, nos lugares pequenos: a equipe da Home, a luta, as listas e as grades |
| [glacier](glacier/) | A Geleira, um bioma raro de gelo dentro da Neve de alguns mapas frios, às vezes com um lago, com pedras grandes de gelo, onde o Hushling e o Echofrost também nascem |
| [volcano](volcano/) | O Vulcão, um bioma épico e raro: um cone íngreme com escadarias, a borda de picos de basalto e a cratera com lava rasa e funda, num mapa comum ou como uma ilha vulcânica no meio do oceano |
| [player-stats](player-stats/) | Os números do Domador no Perfil (vitórias, capturas, distância, biomas pisados, horas jogadas e outros), contados pelo servidor num catálogo de contadores que serve depois às conquistas e ao ranking |
| [start-island](start-island/) | A chegada do mapa sorteado no maior pedaço de terra, nunca num pedacinho que o mar isola |
| [auralis](auralis/) | O Arquipélago Auralis: as ilhas abrindo uma de cada vez pelos Domadores, pelas Arenas e pelas missões, e o mapa aleatório só com o que foi destravado |
| [tamer-level](tamer-level/) | O XP e o nível do Domador, de 1 a 99, pelas lutas e pelos marcos, com a recompensa de cada nível |
| [snelt-line](snelt-line/) | O caracol-fornalha, Snelt, Smeltrudge e Magmollusk (Metal, com o Fogo na final), o primeiro canhão especial lento, com as primeiras Técnicas Especiais de Metal |

As próximas iniciativas estão no [roadmap.md](roadmap.md).

## Ordem de implementação do MVP

As fases dependem umas das outras nesta ordem:

| #   | Fase                                                                       | Status   |
| --- | -------------------------------------------------------------------------- | -------- |
| 1   | [foundation/01-project-setup](foundation/01-project-setup.md)              | concluída |
| 2   | [game-data/01-data-layer](game-data/01-data-layer.md)                      | concluída |
| 3   | [game-data/02-core-tables](game-data/02-core-tables.md)                    | concluída |
| 4   | [game-data/03-starter-content](game-data/03-starter-content.md)            | concluída |
| 5   | [foundation/02-ui-shell](foundation/02-ui-shell.md)                        | concluída |
| 6   | [onboarding/01-title-and-tamer-name](onboarding/01-title-and-tamer-name.md) | concluída |
| 7   | [onboarding/02-starter-selection](onboarding/02-starter-selection.md)      | concluída |
| 8   | [hub/01-hub-screen](hub/01-hub-screen.md)                                  | concluída |

Com as 8 fases concluídas, o MVP de estrutura está pronto. As próximas iniciativas, na ordem sugerida, estão no [roadmap.md](roadmap.md).

## Modelo de spec

```markdown
# NN. Título

- **Status:** rascunho | aprovada | em andamento | concluída
- **Depende de:** specs ou pré-requisitos

## Contexto

Por que esta fase existe e o que já está pronto antes dela.

## Escopo

O que entra.

## Fora do escopo

O que não entra, mesmo parecendo relacionado.

## Requisitos

- **RF-01:** uma frase, um comportamento.

## Critérios de aceite

- [ ] Verificável por alguém que não escreveu o código.

## Desenho técnico

Arquivos a criar e a alterar, com caminho, e o que reutilizar do que já existe.

## Verificação

Comandos e passos manuais para conferir a entrega.

## Tarefas

- [ ] Passos de implementação, na ordem.

## Dúvidas em aberto

Só quando houver. Sem dúvidas, a seção não existe.
```

## Regras

- **A spec é a fonte da verdade.** Leia o `README.md` da iniciativa, o `architecture.md` e a spec da fase antes de implementar. Se a implementação precisar divergir, atualize a spec no mesmo commit e diga o motivo.
- **Cada spec se explica sozinha.** Quem lê não tem o histórico da conversa em que ela nasceu. Cite arquivos pelo caminho (`res://...` para arquivos do jogo) e escreva as decisões com o motivo.
- **Nada implícito.** O que não foi decidido vai em "Dúvidas em aberto" e é resolvido com o dono do projeto antes de virar código. Não invente requisito para fechar lacuna.
- **Propostas a revisar.** Conteúdo criado no planejamento sem aprovação do dono (nomes, números, cores) fica marcado como _a revisar_. Pode ser implementado, mas muda sem cerimônia se o dono pedir.
- **Requisitos numerados e critérios verificáveis.** "A tela abre rápido" não serve; "o botão Começar fica desabilitado com menos de 2 caracteres" serve.
- **Uma fase por vez.** Implemente e valide: o projeto abre no editor sem erros nem avisos de script, o jogo abre com o servidor no ar (o `CatalogValidator` confere o catálogo baixado), os testes do servidor passam (a partir de [backend-api/01](backend-api/01-server-setup.md)) e os passos manuais da spec foram feitos. Marque as tarefas e mude o status da spec e das tabelas (iniciativa e esta) para `concluída` no mesmo commit.
- **O cliente Godot não tem framework de testes** (decisão do dono; o servidor terá, ver [roadmap.md](roadmap.md#decisões-globais-já-tomadas)). A verificação de cada fase é feita pelos testes do servidor e por passos manuais no editor (F5) e, quando fizer sentido, no aparelho; quem implementa diz quais passos fez e quais ficaram para o dono.
- **Nunca usar nomes, termos ou visuais do Pokémon no jogo.** Use o vocabulário do [glossary.md](glossary.md). Nas specs, o nome original só aparece na coluna "Referência" do glossário, nas próprias regras de não usá-lo e na citação da PokeAPI como referência técnica de modelo de dados; nunca em conteúdo do jogo (espécies, técnicas, textos, telas).
- **Sem segredos.** Nada de chaves, senhas ou dados reais de jogadores nas specs.
- Specs são escritas em português. Commits que só mexem em specs usam o prefixo `chore`; os de implementação, `feat` ou `fix`.

## Como rodar o jogo e os testes

O executável do Godot no Windows tem um nome como `Godot_v4.7.2-stable_win64.exe` (nesta máquina, em `C:\Godot\`; para o terminal, use a versão `_console`). Para os comandos das specs funcionarem como estão escritos, deixe-o acessível como `godot` (renomeie uma cópia ou crie um alias no terminal). Na raiz do repositório (o projeto Godot fica em `client/`):

```bash
cd server && npm run start:dev                    # a API, em http://localhost:3100
godot --headless --path client --quit-after 30    # o jogo sem janela: erros de script no console
cd server && npm test && npm run test:e2e         # os testes do servidor
```

O jogo baixa o catálogo da API ao abrir, e o `CatalogValidator` confere tudo o que chega. Um erro nos dados aparece na tela "Erro nos dados do jogo" (F5 no editor) e no console. Até a [backend-api/07](backend-api/07-client-remote-catalog.md), o catálogo era conferido pelo `tools/validate_data.gd`, citado nas specs dessa época.
