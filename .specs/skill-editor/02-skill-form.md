# 02. O formulário de Técnica no F1

- **Status:** concluída (falta o dono usar)
- **Depende de:** [01](01-skill-routes.md), [content-viewer](../content-viewer/README.md)

## Contexto

Depois da [01](01-skill-routes.md), o servidor já cria e salva uma Técnica inteira. Esta fase põe o formulário na aba Técnicas do F1: o botão **Editar** na ficha e o botão **Nova Técnica** em cima da lista ([README](README.md), decisões do dono).

## Escopo

- O botão **Editar** na ficha da Técnica.
- O botão **Nova Técnica** em cima da lista.
- O formulário `SkillForm`, com os campos, os efeitos e quem aprende.
- Salvar, Cancelar e o F1 com os dados novos depois de salvar.

## Fora do escopo

- Editar nas outras abas.
- Apagar uma Técnica ou mudar o `slug` de uma que existe.
- Conferir os dados no jogo antes de mandar: quem confere é o servidor. O formulário só limita os números ao intervalo de cada campo.

## Requisitos

- **RF-01:** A ficha de uma Técnica tem o botão **Editar** à direita do nome. Ele troca a ficha pelo formulário com os dados dela.
- **RF-02:** Em cima da lista, o botão **Nova Técnica** abre o formulário vazio, com os valores iniciais da tabela abaixo.
- **RF-03:** O formulário tem um campo para cada coluna da Técnica do [architecture.md](architecture.md):
  - `slug`: caixa de texto só ao criar. Ao editar, aparece como texto, sem caixa.
  - `name`: caixa de texto. `description`: caixa de várias linhas.
  - Elemento, categoria, alvo e área: listas com os nomes do catálogo.
  - Marca no chão: lista com "Nenhuma" e as marcas do catálogo. Os turnos só aparecem com uma marca escolhida.
  - Os números: caixas de número com o mínimo e o máximo de cada campo.
  - Faz contato e Atravessa: caixas de marcar.
- **RF-04:** O bloco **Efeitos** lista os efeitos em ordem, cada um numa linha:
  - o tipo (lista do catálogo);
  - a chance em %;
  - só os campos que o tipo usa, pela tabela do [architecture.md](architecture.md) (o `EFFECT_PARAMS` do jogo). Os outros vão nulos.
    - `apply_status`: o Estado.
    - `modify_stat`: o alvo (Inimigo, Si mesmo, Todos), o atributo e os estágios (−6 a 6, sem o 0).
    - `heal`, `drain` e `recoil`: o %.
    - `fixed_damage`: o valor, que pode ficar vazio.
    - `flinch`, `multi_turn`, `protect` e `switch`: nenhum.
  - o aviso "A luta ainda não usa este efeito." nos tipos que a luta não usa;
  - os botões ↑ e ↓, para mudar a ordem, e ×, para tirar.

  A lista de tipos não oferece o `set_weather`, que o servidor recusa. O botão **+ Efeito** acrescenta uma linha `apply_status` com 100% e o primeiro Estado.
- **RF-05:** O bloco **Quem aprende** lista, em cada linha, o Ecobeast (lista do catálogo), o método (lista do catálogo), o nível e ×. O nível só aparece com "Por nível" (1 a 100). Com "Ao evoluir", vai 0, e com "Ensinável", vai nulo, sem caixa. O botão **+ Ecobeast** acrescenta uma linha com o primeiro Ecobeast, "Por nível" e nível 1.
- **RF-06:** **Salvar** desabilita os dois botões e manda a Técnica inteira (`EditorApi.save_skill` ou `create_skill`). Com sucesso, o F1 baixa o catálogo de novo, refaz as abas e mostra a ficha da Técnica salva, só leitura.
- **RF-07:** Se o servidor recusa, a mensagem dele aparece em vermelho em cima dos botões, e o formulário continua com o que foi digitado. Sem resposta do servidor, a mensagem é a do `Api` ("Não foi possível conectar ao servidor.").
- **RF-08:** **Cancelar** volta à ficha da Técnica sem mudar nada. Numa Técnica nova, volta à ficha da Técnica escolhida antes, ou à primeira da lista.
- **RF-09:** Escolher outro item na lista, ou trocar de aba, fecha o formulário sem salvar e sem perguntar.

Valores iniciais de uma Técnica nova (_a revisar_):

| Campo | Valor |
| --- | --- |
| `slug`, `name`, `description` | vazios |
| Elemento, categoria | o primeiro de cada lista |
| Alvo | Inimigo |
| Área | Um alvo |
| Poder 40, Precisão 100, PP 20, Prioridade 0, Crítico 0, Countdown 0 | |
| Golpes 1 a 1, Alcance 1 | |
| Marca no chão | Nenhuma |
| Faz contato, Atravessa | não |
| Efeitos, Quem aprende | nenhum |

## Critérios de aceite

- [ ] No F1, mudar o poder de uma Técnica e salvar mostra a ficha com o poder novo. Na próxima luta, o dano muda.
- [ ] Criar uma Técnica com um efeito e um Ecobeast que a aprende no nível 1 a põe na lista, com os arquivos tracejados.
- [x] Salvar com `max_hits` menor que `min_hits` mostra a mensagem do servidor, e o formulário continua preenchido.
- [x] Cancelar volta à ficha sem mudar nada.
- [x] Um efeito `modify_stat` mostra o alvo, o atributo e os estágios. Um `heal` mostra só o %.
- [x] Depois de salvar, o jogo baixa o catálogo sem erro no `CatalogValidator`.
- [x] O jogo abre sem erros nem avisos de script.

## Desenho técnico

**Criar:**
- `res://tools/content_viewer/skill_form.gd` (`class_name SkillForm`, `VBoxContainer`, montado no código):
  - `_init(viewer: ContentViewer, skill_id: int)`, com `-1` para uma Técnica nova.
  - Os sinais `saved(id: int)` e `cancelled()`.
  - `_body() -> Dictionary`, que monta o corpo do [architecture.md](architecture.md) a partir dos campos.
  - Os efeitos e os aprendizes ficam numa lista de linhas, refeita a cada ↑, ↓, × ou +.

**Alterar:**
- `res://tools/content_viewer/skills_tab.gd`:
  - O botão Editar no `_header`.
  - O botão Nova Técnica pelo `add_list_header`.
  - `_edit(id)`, que abre o `SkillForm` pelo `show_custom`.
  - Ao receber `saved`, a aba chama `await GameData.load_catalog()`, `viewer.rebuild()` e `viewer.show_item(ContentViewer.TAB_SKILLS, id)`.
- `res://tools/map_editor/editor_api.gd`: `SKILLS_PATH := "/v1/editor/skills"`, `create_skill(body)` e `save_skill(id, body)`.

**Reutilizar:**
- `ContentViewer.block`, `text` e `row_name`.
- `GameData.get_rows` para as listas.
- `CatalogSchema.EFFECT_PARAMS` para saber os campos de cada tipo de efeito.
- As cores de `UiPalette` (`DANGER` para a mensagem de erro).

## Verificação

```bash
godot --headless --path client --editor --quit
godot --headless --path client --quit-after 30
```

À mão (F5, com o servidor no ar e a conta em `MAP_EDITOR_USER_IDS`), conferir os critérios de aceite. A Técnica de teste criada fica no banco, porque não há como apagar pelo F1. Use um `slug` como `teste_editor` e apague a linha pelo painel do Supabase depois, se quiser.

## Tarefas

- [x] `EditorApi` com as duas chamadas.
- [x] `SkillForm`: os campos.
- [x] `SkillForm`: os efeitos e quem aprende.
- [x] Editar, Nova Técnica, Salvar e Cancelar na aba.
- [x] Jogo sem janela.
- [ ] Os passos à mão, com o dono.

## Resultado da verificação

Em 2026-11-15, sem janela, numa cena temporária (já apagada), com o servidor novo numa porta à parte:

- **Editar:** o formulário abriu uma Técnica com os efeitos em ordem e os 3 Ecobeasts que a aprendem. **Cancelar** voltou à ficha dela.
- **Nova Técnica:** começou com os valores iniciais. Um efeito trocado para `modify_stat` mostrou só o alvo, o atributo e os estágios, e o Estado do `apply_status` foi para nulo.
- **Salvar:** criou `zz_teste_cliente` e depois salvou o poder 90. O catálogo baixado em seguida passou no `CatalogValidator`.
- **Erro:** com `min_hits` 3 e `max_hits` 2, apareceu "O mínimo de golpes não pode passar do máximo." em vermelho, com **Salvar** de novo habilitado.
- **Limpeza:** a Técnica de teste foi apagada do banco.
- **Jogo:** abre sem erros nem avisos de script.
- **Divergência:** sem resposta do servidor, a mensagem é a do `Api` ("Não foi possível conectar ao servidor."), e não uma nova.
- **Falta o dono:** usar o F1 com a janela e conferir na próxima luta o critério do poder.

