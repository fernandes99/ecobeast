# 10. Domador animado no mapa

- **Status:** concluída
- **Depende de:** [09-biome-transitions](09-biome-transitions.md)

## Contexto

Quem aparece no mapa é o retrato do primeiro Ecobeast da equipe, parado no centro da tela, porque não havia sprite de Domador. O dono quer o próprio Domador no mapa, parado quando está parado e correndo quando anda, olhando para onde vai.

A arte, por enquanto, é o template de personagem de Eris Esra, em 16×32, com folhas de parado e corrida em todos os ângulos. Folhas e direções estão em [architecture.md](architecture.md#domador).

## Escopo

- As folhas `idle.png` e `run.png`, com os créditos do autor.
- `TamerSprite`, o nó que monta as animações a partir das folhas.
- A tela do mapa usando o `TamerSprite` no lugar do retrato.

## Fora do escopo

- Roupa e aparência do Domador, e escolha de personagem.
- As outras animações do template.
- Passar atrás de árvores e montanhas: veio na [11](11-depth-planes.md).
- Animar a subida e a descida de um nível.
- Som de passos.

## Requisitos

- **RF-01:** O marcador do mapa é o Domador, não mais o retrato do Ecobeast.
- **RF-02:** O Domador é desenhado na mesma densidade de pixels do mapa: um pixel da folha vale um pixel da arte, sempre em pixels reais inteiros.
- **RF-03:** O ponto entre os pés fica no centro da superfície do hexágono atual.
- **RF-04:** Parado, ele toca a animação de parado sem parar.
- **RF-05:** Ao abrir o mapa, ele olha para a frente, de frente para o jogador.
- **RF-06:** No passo, ele vira para o vizinho tocado e corre até chegar. Na lateral, usa a linha de lado; nas diagonais de baixo e de cima, as linhas de três quartos.
- **RF-07:** Os três vizinhos da esquerda usam a arte da direita espelhada.
- **RF-08:** Um passo dura `TamerSprite.RUN_SECONDS`, de 0,36 s, _a revisar_, o tempo de um ciclo inteiro da corrida.
- **RF-09:** Ao chegar, ele continua olhando para onde foi. Ao voltar da luta, também.
- **RF-10:** No modo de depuração do mapa inteiro, o Domador fica sobre o hexágono do jogador e não encolhe com o mapa.
- **RF-11:** Trocar a arte é trocar as folhas: o número de colunas vem da largura da imagem.

## Critérios de aceite

- [x] Ao abrir o mapa, o Domador aparece parado, de frente, com os pés no centro do hexágono.
- [x] Nos seis vizinhos, ele corre na direção certa, espelhado à esquerda, e descansa olhando para o mesmo lado.
- [x] Um passo mostra o ciclo inteiro da corrida.
- [x] O Domador fica parado na tela, e quem se move é o mapa.
- [x] Cada pixel opaco do quadro aparece igual na tela, com e sem espelho.
- [x] Andar, tocar, voltar da luta e o modo de depuração continuam funcionando.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/tamer/idle.png` e `run.png`: cópias sem alteração das folhas do template. Células de 32×32 px.
- `client/assets/tamer/CREDITOS.md`.
- `client/ui/components/tamer_sprite.gd`, classe `TamerSprite`.

**Alterar**

- `client/screens/exploration/exploration_screen.tscn`: `PlayerMarker` passa a ser um `AnimatedSprite2D` com o script.
- `client/screens/exploration/exploration_screen.gd`: tipo do marcador, duração do passo, `face` e as animações no passo, e a posição e a escala em `_fit_view`.
- [03-exploration-screen](03-exploration-screen.md), [08-current-tile](08-current-tile.md), `architecture.md`, `README.md` e `client/CLAUDE.md`.

**Conceito novo do Godot**

`AnimatedSprite2D` é o nó que troca os quadros sozinho, e `SpriteFrames` é o recurso que lista as animações e os quadros de cada uma. Um `AtlasTexture` é um recorte de uma imagem maior. O `TamerSprite` monta tudo por código, para o tamanho da folha decidir o número de quadros.

## Verificação

A verificação temporária da tela real roda nos quatro tamanhos, contra um servidor de teste, com o gerador de verdade. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Abrir o mapa e conferir o tamanho do Domador.
2. Andar para os seis vizinhos.
3. Sentir a velocidade do passo.
4. Parar sobre colina, pedra e montanha.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Verificação temporária; ver falhar.
- [x] Copiar as folhas e os créditos.
- [x] `TamerSprite` (RF-02, RF-04, RF-06, RF-07, RF-11).
- [x] Tela do mapa (RF-01, RF-03, RF-05, RF-08 a RF-10).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **Mesma densidade de pixels do mapa:** o Domador tem cerca de 16×25 px da arte em um hexágono de 64×58. Maior que isso, só em escala inteira, com o dobro do tamanho, e os pixels dele ficariam mais grossos que os do mapa.
- **O passo dobrou, de 0,18 s para 0,36 s:** em 0,18 s, só caberiam dois quadros dos seis da corrida a uma velocidade normal. Com 0,36 s, um hexágono é um ciclo inteiro, a 16,7 quadros por segundo.
- **Parado a 5 quadros por segundo:** o `.aseprite` traz 100 ms por quadro em tudo, o padrão do programa. Nessa velocidade, a respiração ficava agitada.
- **A linha de costas fica sem uso:** nenhum vizinho está bem em cima. Ela continua na folha, que é uma cópia sem alteração, e a animação já existe.
- **Sem depender da equipe:** o marcador deixa de ler `Session.player.party[0]`.
- **Licença:** o Read Me do template permite usar em jogos, comerciais ou não, e proíbe revender o template. O crédito é apreciado, mas o texto pede crédito e link quando o produto for gratuito. Por garantia, o crédito está em `client/assets/tamer/CREDITOS.md`; o jogo ainda não tem tela de créditos.
- **A arte é provisória:** o dono vai trocar. O template é um boneco sem roupa.
- **Conferência:** a verificação não compilou antes de `TamerSprite`. Depois, passou com 88 de 88 na tela real, contra um servidor de teste, com o gerador de verdade, em 360×640, 405×720, 412×915 e 720×1061: os seis vizinhos, o ciclo inteiro de 6 quadros, o Domador parado na tela, a volta da luta, o modo de depuração, e 0 pixels errados nas quatro comparações com a folha, duas delas com espelho. O projeto abre sem erros nem avisos. O desempenho foi medido na [11](11-depth-planes.md).
- **Falta do dono:** jogar no editor e no celular e dizer se o tamanho e a velocidade estão bons. Nenhum celular foi testado.
