# Content viewer

Uma janela só para o desenvolvimento, que mostra todo o conteúdo do jogo de forma organizada. Ao rodar pelo editor, F1 abre uma janela própria de 1280×720 com as abas Resumo, Ecobeasts, Técnicas, Elementos, Biomas, Itens, Traços, Temperamentos e Estados. Cada aba mostra os dados do catálogo e, ao lado, os arquivos que o jogo usa, marcando o que já existe e o que falta.

## Contexto

Em 2026-11-06, o dono pediu um jeito mais fácil de ver o banco e o conteúdo. Ele quer saber quais Técnicas existem e quais arquivos cada uma tem (ícone, efeito, som), quais Ecobeasts existem, com as Técnicas por nível e as Evoluções, e ter "uma visão completa de conteúdo do jogo, para eu decidir o que falta terminar e o que fazer de conteúdo". O painel do Supabase mostra as tabelas, mas não os sprites andando, o efeito do golpe nem quais arquivos faltam.

Em 2026-11-06, o catálogo que a API envia tem 14 Ecobeasts, 52 Técnicas, 15 Elementos, 7 biomas, 6 itens, 6 Traços, 25 Temperamentos e 8 Estados. Só Ruvo e Ruvak têm todos os sprites, e só o Arranhão tem efeito e som. A pasta `res://assets/terrain/` tem hexágonos com nomes de biomas que não existem (desert, snow, swamp e warm). Os ícones de Técnica (`res://assets/skills/`) existem para 26 das 52 (23, mais os 3 de Instinto que o dono gerou no mesmo dia), mas nenhuma tela os usa ainda.

Os arquivos de `server/prisma/seed-data/` ficaram para trás: têm 9 Ecobeasts, 38 Técnicas e 14 Elementos, porque o dono edita o catálogo pelo painel do Supabase. Os números das specs desta iniciativa vêm do catálogo da API, e os critérios de aceite comparam com ele, não com o seed.

## Quem usa

Só o dono, no PC, com o jogo rodando pelo editor (F5).

## Objetivos

1. Ver de uma vez o que está pronto e o que falta, nos dados e nos arquivos.
2. Ver os sprites e os efeitos andando e ouvir os sons, como no jogo.
3. Não mudar nada do jogo para o jogador: no celular e no jogo exportado, a janela não existe.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| Fica no próprio Godot, aberta com F1, em 16:9 | Pedido do dono. O Godot mostra os sprites e efeitos como no jogo e sabe quais arquivos existem |
| Organização em abas, com lista à esquerda e detalhe à direita | Escolhida pelo dono entre 3 esboços (lista e detalhe, planilha e cartões) |
| A aba Resumo, com as contagens do que está pronto | Aprovado pelo dono |
| Abas de Elementos (forças e fraquezas) e de Biomas (dados e sprites) | Pedido do dono |
| Abas de Itens, Traços, Temperamentos e Estados | O dono aceitou na conversa ("Pode trazer") |
| O algoritmo do mapa fica de fora | O dono pediu para ignorar por enquanto. Os parâmetros moram no código do servidor e a API não os envia |
| Só leitura: editar continua no painel do Supabase | Aprovado pelo dono |

Tomadas no planejamento e apresentadas ao dono (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| F1 só funciona quando o jogo roda pelo editor (`OS.has_feature("editor")`) | Nem um build de depuração no celular pode abrir a janela |
| A janela é uma janela do sistema, separada da do jogo | O jogo é em retrato (720×1280). Numa janela própria, ele continua do mesmo jeito atrás |
| Os dados vêm do catálogo que o jogo já baixou da API (`GameData`) | O Godot fala só com o NestJS, e o catálogo já tem todas as tabelas. Não precisa mudar o servidor |
| Os arquivos são conferidos na pasta do jogo (`res://`), pelos caminhos que o jogo usa | É onde o jogo procura. O que existe e o jogo não procura não aparece como pronto |
| Um arquivo que falta aparece tracejado em vermelho, com o caminho onde o jogo o procura | O dono sabe onde pôr o arquivo |
| Clicar no nome de um item em outro detalhe abre o item na aba dele | O dono passa do Ruvo para o Arranhão sem procurar |
| Sem catálogo (servidor desligado), a janela avisa, oferece "Tentar de novo" e ainda mostra as pastas de Ecobeast | Os arquivos não dependem do servidor |
| O visual usa o tema do jogo, sem capricho | É uma ferramenta de leitura |

## Fora do escopo

- O algoritmo e os parâmetros do mapa.
- Editar, criar ou apagar qualquer dado ou arquivo.
- Busca e filtros nas listas. As maiores têm 52 linhas.
- Os Domadores, as Arenas e o estado do jogador (equipe, Santuário, Mochila).
- Gerar arquivos que faltam a partir da janela.
- Abrir a janela no celular ou no jogo exportado.

## Pré-requisitos

- [board-battle](../board-battle/) concluída: os caminhos dos sprites de luta e dos efeitos vêm dela.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-viewer-window](01-viewer-window.md) | A janela com F1, as abas, o Resumo e a aba Ecobeasts | concluída (falta o dono ver) |
| [02-skills-and-elements](02-skills-and-elements.md) | As abas Técnicas e Elementos, com o efeito tocando e o som | concluída (falta o dono ver) |
| [03-world-and-items](03-world-and-items.md) | As abas Biomas, Itens, Traços, Temperamentos e Estados | rascunho |

O desenho que as 3 fases compartilham está no [architecture.md](architecture.md).
