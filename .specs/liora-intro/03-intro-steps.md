# 03. Os passos da introdução e a entrada nova

- **Status:** concluída
- **Depende de:** [01](01-nameless-tamer.md), [home-island/03](../home-island/03-travel-screen.md), [story/06](../story/06-scene-timeline.md)

## Contexto

Com o Domador sem nome e Liora sem equipe no servidor ([01](01-nameless-tamer.md)), falta o jogo usar isso: entrar direto em Liora, criar o Domador por cima do mapa, escolher o inicial numa cena e mudar o texto pelo corpo ([architecture](architecture.md)). As cenas que usam tudo isso são a [04](04-intro-scenes.md).

## Escopo

- A entrada nova do jogo, sem a tela de nome.
- O componente `TamerEditor` e a criação por cima do mapa.
- Os passos `create_tamer` e `choose_starter`, no tocador, no `StoryValidator` e no F2.
- O `StoryText` com o trecho das duas formas.
- O jogo sem equipe em Liora.
- A criação aberta sozinha quando falta o nome.

## Fora do escopo

- As cenas da introdução (fase 04).
- O trecho das duas formas no diálogo dos NPCs da ilha (`island_npcs.dialogue`). Só as cenas o usam.

## Requisitos

### A entrada

- **RF-01:** `main.gd` e o "Apagar Domador" do Perfil chamam `Home.start()`, que segue a tabela do [architecture](architecture.md#a-entrada-nova-do-jogo): sem Domador, `Session.create_player("")`; com a casa, `Home.go()`; sem casa, a Aparência no modo de entrada (com o nome, se falta), a escolha do inicial ou o Hub. A tela `title` sai do projeto e do `Router`.
- **RF-02:** Sem ilha casa, a entrada é a tela Aparência no modo de entrada, com o campo de nome do `TamerEditor` quando falta o nome, e depois a escolha do inicial, que termina no `Home.go()`.

### A criação

- **RF-03:** `TamerEditor` sai da `appearance_screen.gd` como no [architecture](architecture.md#a-criação-por-cima-do-mapa), e a tela Aparência continua igual para quem já tem nome.
- **RF-04:** O painel de criação em Explorar (`TamerCreatorPanel`, `client/screens/exploration/tamer_creator_panel.gd`) ocupa do meio para baixo da tela, com o `TamerEditor` e o botão "Pronto". Enquanto ele está aberto, a câmera fica no Domador, com o zoom no máximo, e a parte de cima da tela mostra o mapa.
- **RF-05:** Cada mudança no `TamerEditor` veste o Domador do mapa na hora. O "Pronto" fica desabilitado com o nome inválido e mostra "Salvando..." enquanto grava. A gravação é o `Session.set_tamer_name()` (só se faltava o nome) e depois o `save_appearance()`. Um erro aparece no painel e devolve o botão.
- **RF-06:** Quando a gravação termina, o painel some, a câmera volta ao zoom de antes e a cena segue.

### Os passos

- **RF-07:** `create_tamer` abre o painel e espera o "Pronto" ([architecture](architecture.md#os-passos-novos)).
- **RF-08:** `choose_starter`, com o Domador sem inicial, faz `Router.push(&"starter_select", {"story": true})`. Nesse modo, a tela não tem Voltar (nem o do Android), e escolher faz `Router.back()` em vez de ir à casa. A cena segue quando a tela fecha. Com inicial, o passo não faz nada.
- **RF-09:** O `StoryValidator` aceita os dois passos sem campos, e recusa os dois em cenas fora da ilha casa com a mensagem do [architecture](architecture.md#os-passos-novos). A conferência roda ao abrir a ilha na ferramenta Cenas e antes de tocar uma cena. Uma cena recusada não toca, e o console avisa.
- **RF-10:** No F2, os dois passos entram no menu de tipos, no grupo `screen`, com os nomes "Criar o Domador" e "Escolher o inicial", ícones novos em `client/tools/map_editor/icons/story/` (`create_tamer.svg` e `choose_starter.svg`) e sem resumo no cartão. Eles não têm campos; o painel do passo só explica o que ele faz e que só vale na casa. Salvar uma cena fora da casa com um deles grava o arquivo e avisa com o erro.
- **RF-11:** No Testar daqui, `create_tamer` abre o painel com o Domador de verdade e grava de verdade. Isso só muda o nome se ele faltava. `choose_starter` com inicial não faz nada, como no jogo.

### O texto

- **RF-12:** O `StoryPlayer` passa toda fala e toda opção de escolha pelo `StoryText.render`, e o `StoryValidator` confere as mesmas pelo `StoryText.check` ([architecture](architecture.md#o-texto-das-falas)).
- **RF-13:** No F2, a dica do campo de fala vira "Fala · {nome} vira o nome do Domador; {cansado|cansada} muda com o corpo". O cartão da linha do tempo mostra o texto com as chaves, sem trocar.

### Sem equipe e sem nome

- **RF-14:** Em Liora, sem equipe, o jogo segue a tabela do [architecture](architecture.md#liora-sem-equipe). Assim que o inicial é escolhido, o Procurar, o toque nos selvagens e o Menu aparecem sem sair do mapa.
- **RF-15:** Na ilha casa, quando nenhuma cena roda ao entrar (ou a última delas termina) e o Domador ainda não tem nome, o jogo abre o painel de criação sozinho. Isso também vale para o mapa aberto sem nenhuma cena da introdução.

### A cena automática repetível

- **RF-16:** Uma cena `auto` repetível roda no máximo uma vez por entrada na ilha. Hoje, o fim de toda cena procura uma `auto` (`_play_auto()` em `exploration_screen.gd`), e uma `auto` repetível que pode rodar voltaria a rodar sem parar, logo depois de si mesma. O `Story` guarda os `slug` das repetíveis automáticas já tocadas nesta entrada, e esvazia a lista quando o mapa da ilha carrega. A [fase 04](04-intro-scenes.md) usa isso no `avo_segue`. A regra entra no [story/architecture](../story/architecture.md#os-gatilhos).

## Critérios de aceite

- [ ] Uma conta nova abre o app e cai em Liora, sem tela de nome. Sem nenhuma cena, o painel de criação abre sozinho.
- [ ] Uma cena `auto` repetível de teste roda uma vez ao entrar e não volta depois de outra cena; sair e entrar de novo a roda outra vez.
- [ ] Uma cena de teste com `say`, `create_tamer`, `say` com `{nome}` e `{cansado|cansada}` e `choose_starter` cria o Domador por cima do mapa, fala com o nome e a forma certa do corpo, abre a escolha do inicial e, depois da escolha, mostra o Procurar e o Menu.
- [ ] Mudar o cabelo no painel muda o Domador no mapa na hora.
- [ ] Sem equipe, encostar na Viagem e no Refúgio mostra as mensagens do [architecture](architecture.md#liora-sem-equipe).
- [x] O `StoryValidator` recusa `{a|b|c}`, `{x}` e `{`, e recusa `create_tamer` numa cena fora da casa.
- [ ] A tela Aparência do avatar continua funcionando para quem tem nome.

## Desenho técnico

- `client/ui/components/tamer_editor.gd` (novo), a partir da `appearance_screen.gd`.
- `client/screens/exploration/tamer_creator_panel.gd` (novo) e os métodos `story_create_tamer()` e `story_choose_starter()` na `exploration_screen.gd`, chamados pelo `story_player.gd` como os outros `story_*`.
- `client/core/story/story_text.gd` (novo); `story_player.gd` (`_text`) e `story_validator.gd`.
- `client/tools/map_editor/scene_steps.gd`: os tipos, os ícones e o resumo.
- `client/screens/main/main.gd`, `client/screens/starter_select/starter_select_screen.gd` (o modo `story`), `client/screens/hub/profile_debug_panel.gd` e `client/core/autoload/router.gd`.
- Apagar `client/screens/title/`.
- `.specs/story/architecture.md`: a tabela dos passos ganha os dois, e a linha do `open_screen` deixa de dizer que a introdução decide.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

Checagem sem janela (cena temporária em `client/zz_tmp_check/`, apagada no fim): o `StoryText.render` com os dois corpos e o `check` com os casos do critério; o `StoryValidator` com uma cena de passos novos na casa e fora dela.

Manual (F5): os critérios de aceite, com uma conta nova.

## Tarefas

- [x] `StoryText` e o `StoryValidator`.
- [x] `TamerEditor`, a tela Aparência usando ele e o painel de criação.
- [x] Os dois passos no tocador e no F2.
- [x] A entrada nova e a tela de nome apagada.
- [x] Liora sem equipe e a criação aberta sozinha.
- [x] A cena automática repetível uma vez por entrada.
