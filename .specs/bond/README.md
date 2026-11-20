# bond

O Vínculo entre o Domador e cada Ecobeast (`creature_instances.bond`, de 0 a 255) passa a mudar com o jogo, e a evolução por Vínculo passa a valer.

- **Status:** proposta (o desenho depende do dono)

## Contexto

O GDD já prevê o Vínculo ("Amizade; pode gatilhar evolução") e a evolução por ele ("Bond ≥ 220 ao subir de nível"), marcada para depois do lançamento. Em 2026-11-20, o dono pediu que a serpente da [snekit-line](../snekit-line/README.md) evolua "através da amizade com o treinador + level (32)", e isso trouxe o assunto para agora.

**Como está hoje:**

- Todo Ecobeast nasce com Vínculo 70 (`START_BOND` em `server/src/domain/rules/creature-factory.ts`), e nada o faz subir ou descer.
- O servidor só oferece a evolução de gatilho `level`. O `evolutionOffer`, em `server/src/domain/progression/evolution.ts`, ignora os outros gatilhos, e quem o chama é o `progression.service.ts`.
- A tabela `evolutions` já tem `min_bond` e `min_level`, e o catálogo já tem o gatilho 3 (`bond`, "Vínculo").
- O Hushling evolui para o Echofrost com Vínculo 220, sem nível, e hoje nunca evolui.
- O Snekit, da snekit-line, vai ter Vínculo 220 e nível 32 na mesma regra.

## O que o dono precisa decidir

Pergunte uma de cada vez, com uma sugestão sua em cada uma. Antes, use a skill `reference-simulator` para ver como o simulador de referência faz a amizade, se fizer, e leve isso ao dono.

1. **O que faz o Vínculo subir:** lutar na equipe, vencer lutas, subir de nível, ser curado no Refúgio, andar com ele na equipe, ou um item. Quanto sobe cada um?
2. **O que faz ele cair:** desmaiar na luta, ou ficar muito tempo no Santuário. Ou nada?
3. **O Vínculo inicial:** de quem é capturado e de quem é o inicial, que pode começar mais alto.
4. **O que o jogador vê:** um número, corações, uma frase ("Confia muito em você"), ou nada, e em qual tela (Equipe, detalhe do Ecobeast).
5. **A regra da evolução:** no gatilho `bond`, vale ao subir de nível com Vínculo ≥ `min_bond` e, se a regra tiver `min_level`, com nível ≥ `min_level`. O GDD diz "ao subir de nível", e o dono aprovou nível 32 + Vínculo para o Snekit.

## Proposta inicial de Claude (_a revisar com o dono_)

- **Regra:** o `evolutionOffer` passa a aceitar o gatilho `bond`, com as condições do item 5. A oferta e o cancelamento são os mesmos da evolução por nível.
- **Subir:** +3 por luta vencida em que ele lutou, +1 por luta vencida na equipe sem lutar e +2 por nível subido, até 255.
- **Cair:** −5 quando desmaia numa luta, até 0.
- **Começo:** 70 para todos, como hoje, e 120 para o inicial.
- **Tela:** uma linha "Vínculo" no detalhe do Ecobeast, com 5 corações.

Com essa proposta, um Snekit capturado no nível 5 chega a 220 perto do nível 32, se lutar quase sempre. Confira a conta com a curva de XP antes de fechar.

## Fases

As fases saem depois das respostas do dono. A primeira deve conter a regra do `evolutionOffer`, com testes de unidade que mostrem que:

- o Hushling evolui com 220;
- o Snekit não evolui no nível 31 com 255;
- o Snekit não evolui no nível 32 com 219;
- o Snekit evolui no nível 32 com 220.
