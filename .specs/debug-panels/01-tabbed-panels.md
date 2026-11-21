# 01. Os painéis de depuração em abas

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** o Debug de Explorar ([wild-battle](../wild-battle/README.md), [day-night](../day-night/README.md), [story](../story/README.md)) e o F3 da [board-battle/23](../board-battle/23-battle-effect-states.md)

## Escopo

- O componente `DebugTabs` (`client/ui/components/debug_tabs.gd`): uma barra de abas com os estilos do tema e as páginas embaixo.
- O painel `ExplorationDebugPanel` (`client/screens/exploration/exploration_debug_panel.gd`), montado por código, no lugar dos nós `DebugMenu` do `exploration_screen.tscn`.
- O `BattleEffectsDebug` em abas.

## Requisitos

- **RF-01:** O Debug de Explorar tem o título "Debug", o botão de fechar e 5 abas (_a revisar_):

  | Aba | O que tem |
  | --- | --- |
  | Mapa | as chaves Mapa inteiro e Modo deus, o botão Esquecer ilha (só numa ilha) e a lista Cenas da ilha, que toca a cena sem gravar |
  | Spawn | a grade das espécies (as sem folha apagadas) e o Remover spawns |
  | Luta | Teste 2×2 e 3×3, Domador 1×1, 2×2 e 3×3 e o Quase subir de nível |
  | Visual | as chaves Contorno, Pontas arredondadas, Beirada, Sombra no pé e Tom por altura |
  | Hora | a hora do mundo, o controle deslizante, o +1 hora e a Hora real |

- **RF-02:** As ações continuam iguais às de antes, e as que levam para outro lugar (as lutas, o Domador, o Esquecer ilha, o Quase subir de nível, as cenas e o Mapa inteiro) fecham o painel, como antes.
- **RF-03:** A aba aberta fica lembrada até o jogo fechar.
- **RF-04:** O F3 tem, no topo, o título "Depuração (F3)", o Limpar tudo e o botão de fechar; embaixo, o alvo e 3 abas:
  - **Estados:** os 12 estados em 3 colunas.
  - **Atributos:** um atributo por linha (nome, −, valor, +).
  - **Chão:** as 11 marcas em 3 colunas, com o fundo na cor da marca quando ela está no hexágono.
- **RF-05:** As abas do F3 ficam da altura da maior (`DebugTabs.equal_heights`), para o painel não mudar de tamanho ao trocar de aba.

## Critérios de aceite

- [x] O jogo abre sem janela, sem erro novo.
- [x] Os dois painéis montam numa cena de conferência, com as fotos de cada aba.
- [ ] No jogo, o dono confere as 5 abas de Explorar e as 3 do F3.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

## Resultado da verificação

Em 2026-11-20, o jogo sem janela abriu só com os avisos que já existiam, e as telas de Explorar e da luta compilaram. Uma cena temporária montou os dois painéis numa janela de 720 px e salvou a foto de cada aba: com 4 colunas, os nomes dos estados e das marcas cortavam, e as duas grades ficaram com 3. Falta o dono conferir no jogo.
