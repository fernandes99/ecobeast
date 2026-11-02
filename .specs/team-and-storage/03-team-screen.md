# 03. Tela Equipe

- **Status:** concluída
- **Depende de:** [02-storage-screen](02-storage-screen.md)

## Contexto

A aba "Equipe" e o botão de editar do Hub abrem um placeholder (TELAS.md #9). Esta fase cria a tela onde o jogador deixa o time pronto antes de explorar: escolhe quem começa, vê quem precisa de cura e troca com o Santuário. A ordem muda ao segurar e arrastar, a opção B que o dono escolheu entre 2 mockups.

## Escopo

- A tela Equipe, com as 6 vagas.
- Segurar e arrastar para mudar a ordem.
- As ações de um Ecobeast.
- Vaga livre abrindo o Santuário.

## Fora do escopo

- Curar pela tela Equipe.
- Comparar atributos.
- Arrastar um Ecobeast para o Santuário.

## Requisitos

**Tela**

- **RF-01:** A aba "Equipe" e o botão de editar do Hub abrem a tela.
- **RF-02:** A tela mostra uma linha por Ecobeast, na ordem da equipe, e uma linha "Vaga livre: toque para trazer do Santuário" por vaga vazia, sempre depois dos Ecobeasts.
- **RF-03:** Cada linha mostra sprite, nome de exibição, nível, Elementos, status e HP.
- **RF-04:** O primeiro Ecobeast com HP mostra "Começa a luta". Sem ninguém com HP, nenhum mostra.
- **RF-05:** As 6 linhas cabem na tela sem rolar.
- **RF-06:** A tela se atualiza sozinha quando o jogador muda, como o Hub.
- **RF-07:** O voltar fecha o painel aberto e, sem painel, volta à tela anterior.

**Ordem**

- **RF-08:** Segurar uma linha por 0,3 s levanta o Ecobeast, que passa a seguir o dedo na vertical.
- **RF-09:** As outras linhas abrem espaço enquanto o dedo se move.
- **RF-10:** Soltar deixa o Ecobeast na posição e manda a ordem nova ao servidor.
- **RF-11:** Soltar nas vagas livres deixa o Ecobeast em último, nunca depois de uma vaga.
- **RF-12:** Soltar na posição original não chama o servidor.
- **RF-13:** A linha mostra a ordem nova na hora. Se o servidor recusar, a ordem volta e a tela mostra o erro.
- **RF-14:** Durante o pedido, as linhas não aceitam toques.
- **RF-15:** "Começa a luta" acompanha a ordem nova.
- **RF-16:** Com 1 Ecobeast, segurar não levanta nada, e o toque longo conta como toque.
- **RF-17:** Mover o dedo antes de 0,3 s cancela o gesto, e nada acontece.

**Ações**

- **RF-18:** Um toque curto abre o painel de ações, com "Mandar para o Santuário", "Ver detalhes" e "Voltar".
- **RF-19:** "Mandar para o Santuário" move o Ecobeast, e a linha vira uma vaga livre.
- **RF-20:** Com 1 Ecobeast só, "Mandar para o Santuário" fica desativado, com "A equipe precisa de ao menos 1 Ecobeast."
- **RF-21:** Tocar em uma vaga livre abre o Santuário. Ao voltar, a tela mostra quem entrou, na primeira vaga livre.

## Critérios de aceite

- [x] A aba "Equipe" e o botão de editar abrem a tela.
- [x] Com 2 Ecobeasts, aparecem 2 linhas e 4 vagas livres.
- [x] Um Ecobeast com status mostra o status.
- [x] Com o primeiro em 0 HP, "Começa a luta" fica no segundo.
- [x] Segurar e arrastar o terceiro para o topo muda a ordem no Hub.
- [x] Depois de arrastar, a próxima luta começa com quem ficou em primeiro.
- [x] Soltar nas vagas livres deixa o Ecobeast em último.
- [x] Soltar no mesmo lugar não muda nada.
- [x] Um toque curto abre o painel, sem levantar a linha.
- [x] Soltar antes de 0,3 s não muda a ordem.
- [x] Com o servidor fora, a ordem volta, e o erro aparece.
- [x] Mandar para o Santuário tira o Ecobeast do Hub e o põe na grade do Santuário.
- [x] Com 1 Ecobeast, a ação fica desativada, com o motivo.
- [x] A vaga livre abre o Santuário, e o Ecobeast trazido aparece na tela ao voltar.
- [x] O voltar do Android durante o arrasto cancela o gesto, e a ordem não muda.
- [x] Em 360×640, 405×720, 412×915 e 720×1061, as 6 linhas cabem.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/screens/team/team_screen.tscn` e `.gd`: a tela e o arrasto.
- `client/screens/team/team_row.tscn` e `.gd`: a linha, com os sinais `tapped` e `hold_started`.
- `client/ui/icons/grip.svg`: os pontos que mostram que a linha arrasta.

**Alterar**

- `client/core/autoload/router.gd`: `&"team"`.
- `client/screens/hub/hub_screen.gd`: os destinos da aba "Equipe" e do botão de editar.

**Reaproveitar**

`SafeArea`, `CreaturePortrait`, `HpBar`, `ElementBadge`, `CreatureActionsPanel` e `Session.player_changed`.

O toque chega como `InputEventMouseButton` e `InputEventMouseMotion`, porque o Godot converte o toque em mouse por padrão. Por isso, a mesma conta funciona no editor e no celular, sem usar o arrastar e soltar pronto do Godot, que começa ao mover o dedo, sem esperar segurar.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

Uma cena temporária abre a tela contra um servidor de teste, segura e arrasta com eventos de mouse reais, confere os critérios automáticos e salva capturas de tela. As capturas abertas são citadas no relatório.

Passos do dono no editor (F5) e no celular:

1. Segurar e arrastar um Ecobeast para o topo. **No celular, conferir se o toque longo fica natural.**
2. Conferir "Começa a luta" e entrar em uma luta.
3. Mandar um Ecobeast para o Santuário e trazer de volta pela vaga livre.

## Tarefas

- [x] Verificação temporária da tela; ver falhar.
- [x] Linhas, vagas e estados (RF-01 a RF-07).
- [x] Segurar e arrastar (RF-08 a RF-17).
- [x] Ações e vaga livre (RF-18 a RF-21).
- [x] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: tela Equipe`.

## Decisões da implementação

- **Arrastar sem cópia da linha:** a linha segurada sai do layout com `top_level` e continua no lugar dela na árvore, e uma lacuna fica na lista. Mover a lacuna é o que abre espaço. A posição vem da altura do dedo dividida pela altura de uma vaga, sem depender de onde as outras linhas estão.
- **O levantar é uma borda e uma sombra:** o mockup também inclinava e aumentava a linha, mas isso muda a conta da posição na tela. As linhas abrem espaço de uma vez, sem animação. O visual fica para o dono julgar no celular.
- **"Começa a luta" fica na linha do nome:** no mockup, ele vinha com os Elementos, e na largura de 720 ele, dois Elementos e um status mal cabiam. O nome corta sozinho, então essa linha nunca empurra a tela.
- **As linhas crescem com a tela:** como no mockup, as 6 vagas dividem a altura disponível, com um mínimo de 140.
- **O painel não mudou de ordem:** ele é o mesmo do Santuário, com a ação principal em cima. Por isso, "Mandar para o Santuário" vem antes de "Ver detalhes".
- **Toque longo sem arrasto conta como toque:** com 1 Ecobeast ou em uma vaga livre, nada levanta, e soltar abre o painel ou o Santuário.
- **Quem volta entra na primeira vaga livre:** é a regra de `bring`. Se o jogador mandou o segundo para o Santuário e o trouxe de volta, ele volta para o segundo lugar.
- **O sistema também cancela o arrasto:** além do voltar, um toque cancelado pelo sistema e o jogo indo para segundo plano devolvem a linha ao lugar, porque o soltar pode nunca chegar.
- **Rede simulada:** a falta de servidor foi testada trocando o endereço da API por uma porta sem nada.
- **Conferência:** uma cena temporária abriu a tela contra um servidor de teste, com o mouse entrando por `Input.parse_input_event` em pixels da janela, o mesmo caminho de um mouse de verdade, com a escala da tela. Passou com 105 de 105 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar com 11 erros porque a tela não existia. Seis proteções foram desligadas de propósito, e 10 verificações falharam, cobrindo todas elas. Das 36 capturas de tela, 7 foram abertas e revisadas. Os arquivos temporários foram removidos. O toque de verdade fica para o teste do dono no celular.
