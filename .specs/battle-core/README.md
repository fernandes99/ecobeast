# Battle core

O juiz da batalha, no servidor. O jogo diz o que o jogador quer fazer, e o NestJS decide o resto: quem age primeiro, se acertou, quanto de dano, quais efeitos valem e quem venceu. O cliente nunca envia dano nem resultado. A tela de batalha vem na iniciativa seguinte (`battle-screen`).

## Contexto

O jogador já tem um Ecobeast no servidor, com stats calculados, Técnicas e PP ([auth-google](../auth-google/)), e o catálogo tem as Técnicas, os efeitos, os status e os Traços ([game-data](../game-data/)). As fórmulas estão no `GDD.md`, mas nada as executa. Sem esse motor, nenhuma das próximas iniciativas (zonas, captura, progressão, Domadores NPC) existe.

## Quem usa

- A `battle-screen`, que mostra a luta a partir dos eventos.
- As iniciativas que criam batalhas: `wild-battle`, `npc-tamers` e `arenas-league`.

## Objetivos

1. Uma batalha completa roda no servidor, do primeiro turno ao fim, sem o cliente decidir nada.
2. As regras são funções puras, testadas com valores conhecidos.
3. HP, PP e status da equipe ficam gravados quando a batalha termina.
4. Um inimigo escolhe suas ações sozinho.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                         | Motivo                                                                 |
| ----------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Sem troca voluntária de criatura em batalha, por enquanto                                       | Fica para depois                                                       |
| Quando um Ecobeast desmaia, o jogador escolhe o próximo; se todos desmaiarem, é derrota         | Mantém a equipe útil sem abrir a troca livre                           |
| HP, PP e status continuam depois da luta; o Refúgio é a forma de curar tudo                     | Dá sentido ao Refúgio                                                  |
| A batalha fica só na memória do servidor, com uma por jogador                                   | Primeira versão simples; guardar no banco fica para o futuro            |
| Fechar o app no meio da luta abandona a batalha, sem gravar nada                                | Aceito por enquanto, mesmo permitindo escapar de uma derrota            |
| Fugir tem 20% de chance fixa de falhar, _a revisar_                                             | Regra provisória; talvez vire um cálculo com base no inimigo            |
| A fuga que falha gasta o turno, e o inimigo age                                                 | Fugir precisa ter risco                                                |
| Se os dois lados ficarem sem criaturas no mesmo turno, a vitória é do jogador                   | Decisão do dono                                                        |
| Sem PP em todas as Técnicas, o Ecobeast usa um golpe fraco de emergência, com dano a si mesmo   | Sem isso, a luta poderia travar                                        |
| Selvagem escolhe ao acaso entre as Técnicas com PP, com mais chance para as que causam mais dano | Imprevisível, mas não bobo; NPC e Mestres ganham IA própria depois      |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                           | Motivo                                                                          |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| O estado não vai para o cliente                                                   | Ele poderia alterar um turno ou repeti-lo até o sorteio sair bom                |
| A gravação acontece uma vez só, no fim                                            | Enquanto a luta durar, o banco não muda; abandonar não deixa rastro             |
| As regras ficam em `server/src/domain/battle/`, sem Nest nem Prisma               | Mesma regra de `src/domain/`; são testadas sem banco                            |
| O motor recebe o catálogo e a fonte de sorteio por parâmetro                      | Testes repetíveis                                                               |
| Eventos trazem ids e números, sem frases                                          | A `battle-screen` escreve os textos                                             |
| O motor aceita equipes dos dois lados                                             | Os Domadores NPC usam o mesmo motor                                             |
| A rota de começar recebe espécie e nível, atrás de `ENABLE_TEST_BATTLE`           | Ainda não há zonas; em produção, ela fica desligada até a `wild-battle` trocá-la |

## Fora do escopo

- Tela de batalha.
- Zonas, encontros e captura.
- Recompensas: XP, moedas, Treino, subir de nível, Ascensão.
- Itens, em batalha e segurados.
- Troca voluntária de criatura.
- Clima, golpes múltiplos, Técnicas de carregar, dano fixo e Técnicas que trocam: nenhuma Técnica do catálogo os usa.
- Guardar a batalha no banco ou retomá-la depois de fechar o app.
- Servidor com mais de uma instância: a memória é de um processo só. Ao escalar, a batalha precisa ir para o banco ou um cache compartilhado.

## Pré-requisitos

- [auth-google](../auth-google/) concluída.
- [creature-details](../creature-details/) concluída: o dono quis a tela antes do motor.

## Fases

| Fase                                    | Entrega                                                                    | Status   |
| --------------------------------------- | -------------------------------------------------------------------------- | -------- |
| [01-battle-rules](01-battle-rules.md)   | Regras puras: estágios, Precisão, crítico, dano e ordem do turno           | concluída |
| [02-battle-engine](02-battle-engine.md) | O motor do turno: ações, status, efeitos, Traços, fuga, desmaio e IA       | concluída |
| [03-battle-api](03-battle-api.md)       | Batalha na memória, rotas e gravação de HP, PP e status no fim             | aprovada |
