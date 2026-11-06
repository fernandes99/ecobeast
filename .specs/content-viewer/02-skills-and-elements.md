# 02. Técnicas e Elementos

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [01-viewer-window](01-viewer-window.md)

## Contexto

A [fase 01](01-viewer-window.md) criou a janela, o Resumo e a aba Ecobeasts. O dono quer mapear o que falta de cada Técnica ("cada uma delas tem audio, imagem, e etc") e ver os Elementos, com as forças e as fraquezas. No catálogo da API, em 2026-11-06, são 52 Técnicas: 26 com ícone, e só o Arranhão com efeito e som. Os ícones do Arranhão, do Rugido Feroz e da Investida Veloz chegaram durante esta fase, recortados de uma imagem do dono por `art-source/skills/cut_icons.gd`. São 15 Elementos, e 9 deles têm algum Ecobeast. O antigo Fera agora se chama Instinto, o mesmo nome de um Traço, e o Inseto é novo.

## Escopo

- A aba Técnicas, com o efeito tocando e o som.
- A aba Elementos, com as relações de dano e a tabela de todos contra todos.
- Os links entre Ecobeasts, Técnicas e Elementos.
- Os blocos novos do Resumo.

## Fora do escopo

- As abas da [fase 03](03-world-and-items.md). Os nomes de Estados nos efeitos só viram links nela.
- Mostrar quanto de dano uma Técnica causa num Ecobeast: o cálculo é do servidor.

## Requisitos

- **RF-01:** A aba "Técnicas (N)" fica depois de Ecobeasts. A lista segue a ordem do `id`, com uma bolinha na cor do Elemento, o nome e, à direita, quantos dos 3 arquivos (ícone, efeito e som) existem ("1/3"), com as cores da fase 01.
- **RF-02:** O detalhe da Técnica tem, nesta ordem:
  1. o ícone (ou o tracejado), o nome, o selo do Elemento (link para a aba Elementos), a categoria e a descrição;
  2. **Dados:** poder, precisão, PP, prioridade, estágio de crítico, alvo, forma da área, alcance, se atravessa, se faz contato e os golpes (mínimo e máximo, só quando o máximo passa de 1). Um valor vazio aparece como "—", e o poder 0 também: no catálogo, a Técnica de suporte tem poder 0, e não vazio;
  3. **Marca no chão:** o nome do `ground_effects`, o dano por turno em % e os turnos (`ground_turns`). Sem marca, o bloco não aparece;
  4. **Efeitos:** uma linha por `skill_effects` da Técnica, na ordem de `sort_order`, com o tipo (o nome do `effect_types`), a chance em %, o alvo e os campos preenchidos da linha (o Estado, o stat e os estágios com sinal, o %, o valor e os turnos). Sem efeitos, o bloco não aparece;
  5. **Quem aprende:** uma linha por entrada do `species_skills` com a Técnica, ordenada pelo número do Ecobeast, com o nome (link) e o nível (ou o método). Sem ninguém, "Nenhum Ecobeast aprende.";
  6. **Arquivos:** os previews do ícone, do efeito tocando em repetição e do som com "▶ Ouvir", e o tracejado com o caminho para os que faltam.
- **RF-03:** Na aba Ecobeasts, cada nome de Técnica das "Técnicas por nível" vira link para a Técnica.
- **RF-04:** A aba "Elementos (N)" fica depois de Técnicas. A lista segue a ordem do `id`, com a bolinha na cor do Elemento, o nome e, à direita, quantos Ecobeasts o têm. O Elemento raro (`is_rare`) leva "raro" ao lado do nome.
- **RF-05:** O detalhe do Elemento tem, nesta ordem:
  1. o nome num selo grande na cor dele, a cor em hexadecimal e se é raro;
  2. **Atacando:** "Forte contra" (multiplicador 2), "Fraco contra" (0,5) e "Não afeta" (0), cada um com os selos dos Elementos de defesa; um grupo vazio mostra "—";
  3. **Defendendo:** "Sofre mais de" (Elementos que causam 2 nele), "Resiste a" (0,5) e "Imune a" (0), do mesmo jeito;
  4. **Imunidades a Estados:** os nomes dos Estados de `status_condition_immunities` (como "Queimado" no Fogo); sem nenhum, "—";
  5. **Ecobeasts:** os que têm o Elemento em qualquer posição, como links; sem nenhum, "Nenhum Ecobeast deste Elemento.";
  6. **Técnicas:** as do Elemento, como links; sem nenhuma, "Nenhuma Técnica deste Elemento.".
- **RF-06:** Acima da lista e do detalhe, um botão **Tabela de efetividade** troca o detalhe pela tabela inteira, de N × N Elementos: o ataque nas linhas, a defesa nas colunas, com as cores dos Elementos nos cabeçalhos. Cada célula mostra "2", "½" ou "0" num fundo verde, vermelho ou cinza; as de multiplicador 1 ficam vazias. Os cabeçalhos das colunas usam as 4 primeiras letras do nome (com 3, Instinto e Inseto ficavam iguais). Clicar num cabeçalho abre aquele Elemento. Os multiplicadores vêm só de `element_efficacy`: o que não está na tabela vale 1.
- **RF-07:** Os selos de Elemento na aba Ecobeasts e na aba Técnicas viram links para o Elemento.
- **RF-08:** O Resumo ganha os blocos "Técnicas" (o total), "Técnicas com ícone", "Técnicas com efeito" e "Técnicas com som" ("N de M"), e "Elementos com Ecobeast" ("N de M"), com os nomes dos Elementos sem nenhum embaixo. Ganha também a lista "Técnicas que faltam arquivos", ordenada pelo menor nível em que algum Ecobeast as aprende (as que ninguém aprende no fim), cada uma com o que falta e o menor nível.

## Critérios de aceite

- [ ] O Arranhão mostra "3/3" verde, o ícone, Instinto, Física, poder 40, precisão 100, PP 35, alcance 1, um alvo, faz contato; o efeito tocando sem parar e o som tocando no "▶ Ouvir"; e os 8 Ecobeasts que o aprendem em "Quem aprende" (Ruvo, Ruvak, Ruvaroth, Hushling, Echofrost, Clod, Crag e Ingot).
- [ ] Uma Técnica sem efeito e sem som mostra os dois tracejados com `res://assets/effects/skills/<slug>.png` e `res://assets/sounds/skills/<slug>.wav`.
- [ ] O Rugido Feroz mostra "—" no poder e o efeito "Alterar atributo · 100% · Inimigo · Ataque −1".
- [ ] O Fogo mostra: forte contra Flora, Gelo, Metal e Inseto; fraco contra Fogo, Água, Terra e Arcano; sofre mais de Água e Terra; resiste a Fogo, Flora, Gelo, Metal, Luz e Inseto; "Queimado" nas imunidades; e os Ecobeasts de Fogo.
- [ ] A tabela de efetividade tem 15 × 15 células, e 86 delas preenchidas, igual às linhas de `element_efficacy`.
- [ ] O Resumo mostra "1 de 52" com efeito, "1 de 52" com som, "26 de 52" com ícone e "9 de 15" Elementos com Ecobeast, com Volt, Toxina, Luz, Instinto, Arcano e Inseto listados.
- [ ] Clicar em Arranhão no Ruvo abre a Técnica; clicar em Instinto nela abre o Elemento; clicar em Ruvo na aba do Fogo abre o Ruvo.

## Desenho técnico

**Criar:** `res://tools/content_viewer/skills_tab.gd` e `elements_tab.gd`.

**Alterar:** `content_viewer.gd` (as duas abas, `element_link` e os textos de valor vazio), `list_detail.gd` (o espaço acima da lista, para o botão da tabela, e `show_custom`, que mostra a tabela no lugar do detalhe), `species_tab.gd` (os links) e `summary_tab.gd` (os blocos novos). O efeito e o som já tocavam desde a fase 01.

**Reutilizar:** `GameData.get_skill`, `get_element`, `get_elements`, `get_ground_effect` e `get_rows` para `skill_effects`, `effect_types`, `skill_categories`, `skill_targets`, `area_shapes`, `species_skills`, `species_elements`, `element_efficacy` e `status_condition_immunities`. O nome dos Estados e dos stats sai de `GameData.get_status_name` e `get_stat_name` ou das linhas de `status_conditions` e `stats`.

## Verificação

- `godot --headless --path client --quit-after 30` sem erros nem avisos de script.
- O script sem janela da fase 01 ganha: o "3/3" do Arranhão e os 8 Ecobeasts que o aprendem, os 4 números novos do Resumo, as 86 células da tabela e os grupos do Fogo do critério de aceite.
- Manual, com F5: os critérios de aceite. Prints da Técnica Arranhão, de uma Técnica sem arquivos, do Fogo e da tabela de efetividade.

## Tarefas

- [x] A aba Técnicas.
- [x] A aba Elementos e a tabela de efetividade.
- [x] Os links nas abas da fase 01.
- [x] Os blocos novos do Resumo.
- [x] Verificação sem janela e prints com janela.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-06, o projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script.

O script sem janela, com o catálogo da API, deu 0 falhas em 71 conferências (as da fase 01 e as desta): as abas "Técnicas (52)" e "Elementos (15)"; no Resumo, "26 de 52" com ícone, "1 de 52" com efeito e com som, "9 de 15" Elementos com Ecobeast e os 6 sem nenhum; o Arranhão com "3/3", Instinto, Física, os dados, os 8 Ecobeasts que o aprendem, o ícone e o "▶ Ouvir"; o Rugido Feroz com o ícone, "—" no poder, o efeito "Alterar atributo · 100% · Inimigo · Ataque −1" e os caminhos do efeito e do som; os 4 grupos do Fogo e o Queimado; a tabela de 15 × 15 com 86 células preenchidas; e os links do Arranhão no Ruvo, do selo Instinto no Arranhão e do Ruvo no Fogo.

O poder do Rugido Feroz no catálogo é 0, e não vazio: o "—" passou a valer também para o poder 0.

Prints com janela mostraram o Resumo, o Arranhão, o Rugido Feroz, o Fogo e a tabela. Eles pegaram os cabeçalhos iguais de Instinto e Inseto, já corrigidos. Falta o dono ver com F5.
