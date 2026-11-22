# skill-tree

O Domador ganha uma árvore de habilidades, aprendidas com os pontos que vêm do nível dele. A raiz é a habilidade Domador, obrigatória, que libera as Esferas. Dela saem três ramos: Vínculo (a captura e os Ecobeasts), Caminho (andar, subir e nadar) e Comércio (a Loja e as moedas).

- **Status:** proposta (mapeada com o dono; nada no jogo ainda)

## Contexto

Na [tamer-level](../tamer-level/README.md#o-futuro-a-árvore-de-melhorias), o dono pediu "algum sistema de skills e melhorias. Tipo um arvore de skill que vai liberando pontos conforme upa o nivel, tipo como funciona no Arc raiders". Em 2026-11-22, ele voltou ao assunto: "Quero montar pelo menos as ideias, não faremos agora mas vamos mapear as habilidades". As referências dele são o Arc Raiders, o Far Cry e, principalmente, a árvore de habilidades do EvoCreo (a aba Bio).

A árvore do EvoCreo tem 16 habilidades, de 1 a 20 pontos. A primeira, de 1 ponto, só reconhece o jogador como domador. Outras dobram o dinheiro dos treinadores, curam o capturado, cortam o preço dos itens pela metade e aumentam a velocidade. Ela também pode ser zerada, devolvendo os pontos.

O dono trouxe a lista de habilidades e pediu nomes sem "I, II e III". Os nomes daqui são sugestões de Claude que ele aprovou.

**Como está hoje:**

- O nível do Domador vai de 1 a 99 (`players.level`), sem nenhuma coluna de pontos.
- Todo Domador captura desde o começo.
- Todo Domador sobe e desce até 2 níveis de altura entre dois hexágonos. Com 3 ou mais é paredão (`MAX_CLIMB = 2`, em `server/src/domain/exploration/map-slopes.ts` e `client/domain/models/exploration_map.gd`).
- A água bloqueia o andar. A ponte é o único jeito de atravessar.
- O Vínculo não muda com o jogo. A [bond](../bond/) ainda é uma proposta.

## Objetivos

1. O Domador junta pontos pelo nível e escolhe a ordem em que aprende as habilidades.
2. A habilidade Domador é a primeira de todas. Sem ela, o jogador não usa Esferas nem captura.
3. Até o nível 99 dá para aprender a árvore inteira. A escolha é só a ordem.
4. A árvore cresce depois: sobram pontos para as habilidades que ainda vão entrar.

## Anti-objetivos

- Pontos comprados com dinheiro de verdade.
- Uma habilidade que mude a regra da luta (dano, crítico, countdown). A árvore ajuda a explorar, a capturar e a comprar; a luta continua igual para todos.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| A primeira habilidade é a Domador, de 1 ponto e obrigatória, e só ela libera as Esferas e a captura | "antes dessa skill o player não vai poder usar as esferas e capturar qualquer Eco" |
| Os nomes não usam "I, II e III" | "não gosto muito desse I II e III" |
| Todo Domador sobe 1 degrau, e a Escalada libera 2 | "todos vão poder pelo menos subir um degrau"; depois: "Remova o salto só vai ter a escalada que vai poder subir 2 degrais, 3 degrais fica demais" |
| O Nadador entra na água rasa sem precisar de um Ecobeast | "ele vai poder entrar em agua rasa sem precisar de um ecobeast" |
| Dá para aprender a árvore inteira | "Vai dar para aprender tudo" |
| Os nomes, os custos e as ligações da tabela abaixo | "Escrever a spec", depois de ver a tabela |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui):

| Decisão | Motivo |
| --- | --- |
| O Domador ganha 1 ponto ao ser criado e mais 1 por nível subido: 99 pontos no nível 99 | A tamer-level já previa 1 por nível, e o ponto da criação paga a Domador logo no começo |
| A árvore custa 84 pontos, e sobram 15 | As habilidades que o dono já citou e ainda não existem (limite de inventário e montaria) cabem depois |
| As mais úteis custam menos | O nível 99 é difícil de alcançar, e a maioria nunca vai ter a árvore inteira |
| Sem o botão de zerar | Como dá para aprender tudo, a escolha é só a ordem |
| Os descontos da Loja não somam: vale o maior aprendido | São três degraus da mesma habilidade |
| Quem já tem Ecobeast quando a árvore chegar ganha a Domador de presente, sem gastar ponto | Senão, quem já captura perderia a captura |
| A árvore fica no Perfil, e o avatar do Hub ganha um aviso quando há ponto para gastar | O Perfil já mostra o nível; no EvoCreo, a árvore também fica na tela do personagem |

## A árvore

Cada habilidade pede a de cima no mesmo ramo; a Escalada, o Nadador e a Patrocínio dizem na tabela qual pedem.

```
                       Domador (obrigatória)
        ┌─────────────────────┼─────────────────────┐
     Vínculo               Caminho               Comércio
     Acolhida              Passo ligeiro         Pechincha
     Afinidade             Corredor              Lábia
     Boa linhagem          Pés de vento          Mestre da barganha
                           Escalada              Patrocínio
                           Nadador
```

| Ramo | Habilidade | Custo | Pede antes | O que faz |
| --- | --- | --- | --- | --- |
| Raiz | **Domador** | 1 | — | Libera as Esferas e a captura |
| Vínculo | **Acolhida** | 3 | Domador | O Ecobeast capturado sai curado: o HP, os estados e o PP |
| Vínculo | **Afinidade** | 6 | Acolhida | O Vínculo sobe mais rápido (depende da [bond](../bond/)) |
| Vínculo | **Boa linhagem** | 12 | Afinidade | Mais chance de Genes altos no capturado |
| Caminho | **Passo ligeiro** | 3 | Domador | O Domador anda mais rápido |
| Caminho | **Corredor** | 6 | Passo ligeiro | Mais rápido ainda |
| Caminho | **Pés de vento** | 10 | Corredor | A velocidade mais alta |
| Caminho | **Escalada** | 8 | Domador | Sobe e desce 2 níveis entre dois hexágonos, em vez de 1 |
| Caminho | **Nadador** | 8 | Domador | Anda na Água rasa; a Água profunda continua bloqueando |
| Comércio | **Pechincha** | 3 | Domador | 5% de desconto em toda a Loja |
| Comércio | **Lábia** | 6 | Pechincha | 10% de desconto |
| Comércio | **Mestre da barganha** | 10 | Lábia | 15% de desconto |
| Comércio | **Patrocínio** | 8 | Pechincha | Os Domadores NPC pagam o dobro de moedas quando perdem |

Total: 84 pontos.

## O que cada habilidade mexe

Para planejar as fases. O servidor decide todas; o cliente só mostra.

- **Os pontos:** os pontos do Domador são 1 + (`players.level` − 1), menos o custo das habilidades aprendidas. A proposta é um catálogo `tamer_skills` (nome, ramo, custo, `parent_skill_id`) e a tabela `player_tamer_skills`, com a rota de aprender conferindo os pontos e a habilidade de antes.
- **Domador:** o servidor recusa a Esfera na luta e o cliente esconde o botão até ela ser aprendida. O jogador novo aprende a Domador depois de escolher o inicial. Quem já tem Ecobeast ganha ela por uma migração.
- **Escalada:** a regra de hoje (`MAX_CLIMB = 2`) vira a regra de quem tem a Escalada, e a de todos passa a ser 1. Isso pede:
  - a conferência do passo no servidor e no cliente pelo Domador, e não mais por uma constante;
  - o gerador do mapa sorteado abrindo as escadarias só com degraus de 1 (`openRamps`) e garantindo o alcance da terra contando com 1 (`openSlopes`, `climbReach`);
  - o paredão do vulcão continuando com 3 (hoje `WALL = MAX_CLIMB + 1`, em `map-volcano.ts`);
  - a camada Bloqueios do F2 marcando a partir de 2 (`editor_canvas.gd`), para o dono acertar as encostas das ilhas, como as de Liora.
- **Nadador:** a Água rasa deixa de bloquear quem tem a habilidade (`HexTile.blocks_walking` e a conferência do passo no servidor). A Praia fica 1 nível acima da água, então o degrau de todos já basta. Na Água rasa, o Procurar enfrenta o Ecobeast do próprio hexágono.
- **Passo ligeiro, Corredor e Pés de vento:** a velocidade do Domador (`WalkRoute.WALK_SPEED`, hoje 130) sobe para 145, 160 e 175. O teto do contador de hexágonos andados (`MIN_STEP_MS`, hoje 300 ms, em `hex.ts`) cai na mesma proporção.
- **Pechincha, Lábia e Mestre da barganha:** o preço da compra (`inventory.service.ts`) sai com o desconto, arredondado para baixo, e a Loja mostra o preço com desconto.
- **Patrocínio:** as moedas da vitória contra um Domador NPC (`TAMER_COINS_WIN_BASE`, em `coins.ts`) dobram. As de selvagem não mudam.
- **Acolhida:** o Ecobeast capturado vai para a equipe ou para o Santuário com o HP cheio, sem estados e com o PP cheio.
- **Afinidade:** o Vínculo ganho sobe 50%. Só faz efeito depois que a [bond](../bond/) fizer o Vínculo mudar.
- **Boa linhagem:** os Genes do selvagem são sorteados duas vezes, e fica o total maior (`genesTotal`, em `genes.ts`). Falta conferir em que momento o servidor sorteia os Genes do selvagem, se no nascimento ou na captura.

## Perguntas em aberto

- A tela da árvore: o desenho dela no Perfil.
- Os números dos efeitos (a velocidade, os 50% da Afinidade, os dois sorteios da Boa linhagem) são propostas para conferir no jogo.
- As habilidades que vêm depois, com os 15 pontos que sobram: o limite de inventário e a montaria, citados pelo dono na tamer-level.

## Fases

As fases saem quando o dono decidir fazer a árvore. A primeira deve trazer o catálogo, os pontos, a rota de aprender e a Domador liberando a captura. Os ramos podem vir um de cada vez. A Afinidade espera a bond.
