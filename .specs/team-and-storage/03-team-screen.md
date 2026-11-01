# 03. Tela Equipe

- **Status:** rascunho
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
- **RF-02:** A tela mostra uma linha por Ecobeast, na ordem da equipe, e uma linha "Vaga livre" por vaga vazia, sempre depois dos Ecobeasts.
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
- **RF-16:** Com 1 Ecobeast, segurar não levanta nada.
- **RF-17:** Mover o dedo antes de 0,3 s cancela o gesto, e nada acontece.

**Ações**

- **RF-18:** Um toque curto abre o painel de ações, com "Ver detalhes", "Mandar para o Santuário" e "Voltar".
- **RF-19:** "Mandar para o Santuário" move o Ecobeast, e a linha vira uma vaga livre.
- **RF-20:** Com 1 Ecobeast só, "Mandar para o Santuário" fica desativado, com "A equipe precisa de ao menos 1 Ecobeast."
- **RF-21:** Tocar em uma vaga livre abre o Santuário. Ao voltar, a tela mostra quem entrou.

## Critérios de aceite

- [ ] A aba "Equipe" e o botão de editar abrem a tela.
- [ ] Com 2 Ecobeasts, aparecem 2 linhas e 4 vagas livres.
- [ ] Um Ecobeast com status mostra o status.
- [ ] Com o primeiro em 0 HP, "Começa a luta" fica no segundo.
- [ ] Segurar e arrastar o terceiro para o topo muda a ordem no Hub.
- [ ] Depois de arrastar, a próxima luta começa com quem ficou em primeiro.
- [ ] Soltar nas vagas livres deixa o Ecobeast em último.
- [ ] Soltar no mesmo lugar não muda nada.
- [ ] Um toque curto abre o painel, sem levantar a linha.
- [ ] Soltar antes de 0,3 s não muda a ordem.
- [ ] Com o servidor fora, a ordem volta, e o erro aparece.
- [ ] Mandar para o Santuário tira o Ecobeast do Hub e o põe na grade do Santuário.
- [ ] Com 1 Ecobeast, a ação fica desativada, com o motivo.
- [ ] A vaga livre abre o Santuário, e o Ecobeast trazido aparece na tela ao voltar.
- [ ] O voltar do Android durante o arrasto cancela o gesto, e a ordem não muda.
- [ ] Em 360×640, 405×720, 412×915 e 720×1061, as 6 linhas cabem.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/screens/team/team_screen.tscn` e `.gd`: a tela e o arrasto.
- `client/screens/team/team_row.tscn` e `.gd`: a linha, com os sinais `tapped` e `hold_started`.

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

- [ ] Verificação temporária da tela; ver falhar.
- [ ] Linhas, vagas e estados (RF-01 a RF-07).
- [ ] Segurar e arrastar (RF-08 a RF-17).
- [ ] Ações e vaga livre (RF-18 a RF-21).
- [ ] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: tela Equipe`.
