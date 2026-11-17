# editor-performance

O editor de ilhas (F2) para de travar ao decorar, apagar e pôr caminho numa ilha cheia, e ganha um botão que desliga as animações do mapa.

## Contexto

Em 2026-11-17, o dono disse: "O map editor ta começando a ficar bem lento, principalmente quando começo a decorar, remover decorações, colocar caminho e etc". Ele perguntou se uma flag para desligar as animações ajudaria.

Medido sem janela, numa ilha de 3.781 hexágonos com 15.000 peças (4.750 linhas de bloqueio) e 4 pontes:

| O quê | Quando | Tempo |
| --- | --- | --- |
| Os pedaços das pontes se juntam de novo à lista a cada hexágono redesenhado, sem apagar os de antes | Toda pincelada | De 1.824 pedaços para 184 mil em 100 pinceladas; 25 pinceladas passam de 271 ms para 1.112 ms |
| `_refresh_blocks`, as linhas e os hexágonos bloqueados de todas as peças | Cada passo da Borracha, do Remover, da ferramenta Peças e do Bloqueios, cada movimento ao arrastar uma peça, e cada desfazer | 876 ms |
| `refresh_props`, que converte todas as peças | Os mesmos | 135 ms, mais o `_refresh_blocks` |
| Desenhar os bloqueios da ilha inteira | Cada movimento do mouse, junto com o contorno do pincel | ~30 ms por quadro, contra ~2 ms sem eles |
| A Borracha procura as peças de cada hexágono do pincel em todas as peças | Cada passo dela | ~11 ms por hexágono |
| O desfazer copia e compara todas as peças | Começo e fim de toda pincelada, de qualquer ferramenta | ~40 ms |

As animações (vento, água, fumaça) pesam na placa de vídeo, não nesses travões.

## Objetivos

1. Cada passo de uma ferramenta refaz só os hexágonos e as peças que ele mexeu.
2. O editor fica do mesmo tamanho, por mais pinceladas que se deem.
3. O botão Animações, nas Camadas do F2, para o vento, a água e a fumaça, e aí o Godot só redesenha o editor quando algo muda.

## Anti-objetivos

- O que o editor mostra e salva não muda.
- Explorar e a luta não mudam: as animações seguem ligadas neles.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os bloqueios ficam guardados por hexágono de peça, com quantas peças bloqueiam cada hexágono | Mexer numa peça refaz só o hexágono dela. A conta inteira fica para quando a ilha abre |
| Os bloqueios são desenhados numa camada própria, só dentro da tela, e redesenhados só quando eles, a vista ou o terreno mudam | O contorno do pincel segue o mouse a cada movimento. Com os bloqueios na mesma camada, a ilha inteira de bloqueios era redesenhada junto |
| O `refresh_props` acha os hexágonos que mudaram por uma chave de cada peça do rascunho (`Dictionary.hash`), sem converter as peças | Converter 15.000 peças a cada desfazer pesa, e a chave também pega o bloqueio ajustado, que a chave de antes não via |
| A água, o vento e a fumaça andam pelo `map_time` do `HexMapView`, não pelo `TIME` do Godot | Com o `TIME` no shader, o Godot redesenha a tela a cada quadro, mesmo no modo de pouco processamento. Pelo `map_time`, parar as animações para também o redesenho |
| O `map_time` volta a 0 a cada 3.600 s, como o `TIME` | As velocidades da água fecham voltas inteiras em 3.600 s |
| O botão começa ligado e fica guardado no aparelho (`user://view.json`) | O editor segue como era até o dono desligar, e a escolha vale na próxima vez |
| O botão para todos os mapas abertos, o da janela do jogo também, só enquanto o editor estiver aberto | O editor abre numa janela própria, e o mapa da janela do jogo atrás pediria redesenho a cada quadro. O jogo sem o editor não muda |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-editor-speed](01-editor-speed.md) | As pontes sem repetição, as peças e os bloqueios refeitos por hexágono, a Borracha numa passada, o desfazer só nas ferramentas de peça e o botão Animações | concluída (falta o dono conferir) |
