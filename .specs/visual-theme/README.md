# Visual theme

O visual do jogo inteiro: uma paleta escura de azul-marinho, painéis arredondados com borda clara, cores vivas para ações e Elementos, e o Hub no layout do protótipo do dono. A interface é feita com formas do tema do Godot e ícones simples; as ilustrações (cenário, criaturas, imagens das ações) vêm do dono e entram em espaços já previstos.

## Contexto

O MVP usa um tema claro provisório (fundo creme, botões verdes, só texto), criado em [foundation/02](../foundation/02-ui-shell.md) antes de existir direção de arte. O dono gerou um protótipo do Hub (`.specs/visual-theme/hub-prototype.png`) e decidiu que essa paleta vale para o jogo todo. As artes das criaturas já começaram a chegar (`res://assets/creatures/<slug>/front.png`).

## Quem usa

Todo jogador, em todas as telas. Quem implementa telas novas, que passam a seguir esta paleta e estes componentes.

## Objetivos

1. Todas as telas existentes (entrada, escolha do inicial, confirmação, Hub, placeholder, erros) usam a paleta escura, sem nenhuma cor do tema antigo.
2. O Hub fica o mais parecido possível com o protótipo, só com formas, ícones e as artes que já existem.
3. Uma ilustração nova do dono entra no jogo colocando o arquivo no caminho combinado, sem mudar código.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                       | Motivo                                                          |
| --------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| A paleta do protótipo vale para o jogo inteiro                                                | Identidade única                                                |
| Claude faz a interface com formas do tema e ícones simples; ilustrações são do dono           | Claude não gera ilustrações; o dono gera as imagens em outra ferramenta |
| O que o jogo ainda não tem fica fora do Hub: gemas, engrenagem de configurações, botões "+" das moedas, "Equipe ativa" | O protótipo foi gerado por cima; não se mostra o que não existe |
| Texto e números nunca fazem parte de uma imagem                                               | Mudam a todo momento e precisam ser legíveis                    |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                                                   | Motivo                                                                                   |
| --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| As cores foram medidas no protótipo (média de 7 × 7 pixels por ponto) e arredondadas numa paleta curta     | Fidelidade ao protótipo sem herdar o ruído da imagem gerada                              |
| Títulos em Nunito com peso 900 (Black), uma `FontVariation` nova da fonte que já está no projeto           | O protótipo usa uma fonte arredondada e grossa; a Nunito variável chega perto sem fonte nova |
| Ícones em SVG, de uma cor só (branco), desenhados no projeto e tingidos pelo código (`modulate`)           | Ficam nítidos em qualquer tela e mudam de cor com o estado (aba ativa, desabilitado)     |
| Espaço de ilustração mostra o arquivo combinado se ele existir; senão, um gradiente com um ícone simples   | Mesmo padrão do retrato das criaturas: a arte entra sem mudar código                     |
| A barra de XP do Domador aparece vazia                                                                     | O GDD ainda não define como o Domador sobe de nível ([roadmap](../roadmap.md#dúvidas-globais-em-aberto)) |
| Conferência visual por capturas do Movie Maker do Godot (`--write-movie`)                                  | O cliente não tem testes automáticos; a captura deixa quem implementa ver a tela         |

## Paleta

`res://ui/theme/palette.gd` (`UiPalette`) passa a ter estas cores; `main_theme.tres` repete as mesmas nos estilos.

| Nome              | Cor         | Uso                                                        |
| ----------------- | ----------- | ---------------------------------------------------------- |
| `BACKGROUND`      | `#0F2337`   | Fundo das telas                                            |
| `BACKGROUND_DEEP` | `#0A1A2B`   | Base do gradiente do fundo                                 |
| `SURFACE`         | `#142A43`   | Painéis e barra inferior                                   |
| `SURFACE_RAISED`  | `#1E3C58`   | Chips, campos, botões secundários, slots vazios            |
| `BORDER`          | `#1D4665`   | Borda dos painéis                                          |
| `TRACK`           | `#103654`   | Fundo das barras (HP, XP)                                  |
| `TEXT`            | `#FFFFFF`   | Texto principal                                            |
| `TEXT_SECONDARY`  | `#9DB7D2`   | Texto de apoio, ícones inativos                            |
| `TEXT_MUTED`      | `#59708E`   | Texto sem importância ("Vazio"), nunca informação essencial |
| `PRIMARY`         | `#0E5FAF`   | Botão principal, aba atual                                 |
| `PRIMARY_PRESSED` | `#094C92`   | Botão principal pressionado                                |
| `ACCENT`          | `#0DA4F6`   | XP, foco, destaques, anel do avatar                        |
| `WARNING`         | `#F2B33D`   | Moedas, HP médio                                           |
| `DANGER`          | `#E5534B`   | Erro, ação destrutiva, HP baixo                            |
| `DANGER_PRESSED`  | `#C0433C`   | Botão de perigo pressionado                                |
| `HP_HIGH`         | `#68C661`   | HP acima de 50%                                            |
| `OVERLAY`         | `#000000` a 60% | Escurece a tela atrás de um painel de confirmação      |

Contraste mínimo de 4,5 : 1 para texto que carrega informação: `TEXT` e `TEXT_SECONDARY` passam sobre `BACKGROUND`, `SURFACE` e `SURFACE_RAISED`; `TEXT_MUTED` não, e por isso só aparece em texto dispensável.

## Arquivos de ilustração

| Arquivo                                   | Onde aparece                         | Tamanho sugerido para gerar |
| ----------------------------------------- | ------------------------------------ | --------------------------- |
| `res://assets/creatures/<slug>/front.png` | Retratos (já existe)                 | 512 × 512, fundo transparente |
| `res://assets/backgrounds/hub.png`        | Cenário do topo do Hub               | 1440 × 900, sem transparência |
| `res://assets/ui/actions/<ação>.png`      | Topo de cada card de ação do Hub     | 512 × 320, fundo transparente |

Os ids das ações estão em [02-hub-layout](02-hub-layout.md).

## Fora do escopo

- Ilustrações (são do dono).
- Animações além do retorno de toque; sons.
- Telas novas (cada iniciativa futura faz a sua, já nesta paleta).

## Pré-requisitos

- [hub/01-hub-screen](../hub/01-hub-screen.md) concluída.

## Fases

| Fase                                | Entrega                                                                       | Status   |
| ----------------------------------- | ----------------------------------------------------------------------------- | -------- |
| [01-dark-theme](01-dark-theme.md)   | Paleta, fonte e tema escuros aplicados a todas as telas existentes           | rascunho |
| [02-hub-layout](02-hub-layout.md)   | Hub no layout do protótipo: topo, equipe em linha, cards de ação e barra com ícones | rascunho |
