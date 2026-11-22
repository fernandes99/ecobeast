# creature-roles

Os papéis dos Ecobeasts na luta: 5 famílias e os subpapéis delas, a regra que toda linha nova segue e as mecânicas que faltam no motor para cada subpapel existir de verdade.

## Contexto

Em 2026-11-22, ao pensar nas linhas Comuns do Campo florido, o dono pediu os papéis dos Ecobeasts organizados, sem ficar preso ao que já existe, e depois pediu que eles virassem a regra do projeto: "vamos seguir de forma organizada essas rules e subrules", começando a seguir agora, sem mudar nada no jogo.

Até aqui, o papel de cada linha era só uma frase na spec dela ("o primeiro tanque especial", "o primeiro de controle") e o palpite da skill `catalog-balance` pelos atributos da forma final. Com isso, 11 das 17 formas finais saíram Atacantes, e Guardião, Suporte e Controlador ficaram com um Ecobeast cada.

## Objetivos

1. Um vocabulário único de papel e subpapel, usado nas specs de linha, na skill `catalog-balance` e nas conversas com o dono.
2. A regra para toda linha nova declarar o papel, o subpapel e o secundário, e mostrar como os atributos, o Traço e as Técnicas sustentam isso.
3. A lista do que o motor da luta ainda não faz para cada subpapel, para virar iniciativas na ordem de valor.

## Anti-objetivos

- Mudar agora um Ecobeast que já existe: os papéis de hoje ficam como estão, só registrados abaixo.
- Uma regra de jogo que leia o papel: por enquanto ele é só desenho, não muda dano, IA nem sorteio.

## Os papéis

Cada Ecobeast tem **um papel principal** (a família e o subpapel) e pode ter **um secundário**, que vem das Técnicas dele.

Marca do motor: ✅ dá para fazer hoje; ◐ dá em parte; 🆕 pede uma regra nova no servidor.

### 1. Guardião

Absorve o dano pelo time. Atributos: (HP + Defesa) / 2 ou (HP + Def. Especial) / 2 pelo menos 15 acima do maior ataque.

| Subpapel | O que faz | Motor |
| --- | --- | --- |
| **Muralha** (física, especial ou mista) | Aguenta muito, sobe as próprias defesas, se protege e se cura | ✅ |
| **Provocador** | Obriga os inimigos perto a mirar nele por algumas vezes | 🆕 Provocar |
| **Guarda-costas** | Protege um aliado vizinho e toma o golpe no lugar dele | 🆕 Proteger aliado / desviar o golpe |

### 2. Suporte

Faz o time durar e render mais. Atributos: como os do Guardião, com o HP e a Def. Especial em destaque. Técnicas: 40% ou mais voltadas para os aliados.

| Subpapel | O que faz | Motor |
| --- | --- | --- |
| **Curandeiro** | Cura o HP de um aliado ou em área e cura aos poucos (Brotando, Jardim) | ✅ |
| | Revive um aliado derrubado | 🆕 Reviver |
| | Tira os estados ruins de um aliado | 🆕 Limpar estados |
| **Protetor** | Sobe a Defesa e a Def. Especial dos aliados | ✅ |
| | Dá um escudo que absorve dano | 🆕 Escudo |
| **Inspirador** | Sobe o Ataque, o Ataque Especial, a Velocidade ou a precisão dos aliados | ✅ |
| | Adianta a vez de um aliado na fila | 🆕 Adiantar a vez |

### 3. Controlador

Atrapalha o inimigo em vez de causar dano. Atributos: equilibrados, com a Velocidade média. Técnicas: 3 ou mais de controle (um estado de certeza ou com 30% ou mais, uma marca no chão contra o inimigo, baixar um atributo de certeza, o Teleporte).

| Subpapel | O que faz | Motor |
| --- | --- | --- |
| **Enfraquecedor** | Baixa os atributos do inimigo | ✅ |
| **Perturbador** | Põe estados: Paralisado, Sono, Confusão, Atordoado, Preso | ✅ |
| **Arquiteto** | Espalha marcas no chão que machucam, prendem ou atrasam | ✅ |
| | Cria obstáculos que bloqueiam hexágonos | 🆕 Obstáculo |
| **Posicionador** | Teleporta (o Teleporte do Gatemoth) | ✅ |
| | Empurra ou puxa o inimigo, de preferência para dentro das marcas | 🆕 Empurrar e puxar |

### 4. Atacante

Derruba depressa. Atributos: o maior ataque bem acima das defesas.

| Subpapel | O que faz | Motor |
| --- | --- | --- |
| **Veloz** | Muito rápido (Velocidade 100 ou mais), crítico alto ou prioridade; acaba com quem está fraco | ✅ |
| **Canhão** | Lento (60 ou menos), com o ataque altíssimo e golpes em área | ✅ |
| **Atirador** | Alcance longo (3 a 6 hexágonos), frágil, precisa ficar longe | ◐ o alcance existe, falta o Ecobeast pensado para isso |

### 5. Lutador

Bate e aguenta, sempre perto do inimigo, sem ser o melhor em nenhum dos dois. Atributos: o maior ataque perto das defesas (até 10 abaixo).

| Subpapel | O que faz | Motor |
| --- | --- | --- |
| **Brigão** | Fica de pé no corpo a corpo: drena o HP, se cura ou sobe a defesa | ✅ |
| **Contra-atacador** | Devolve parte do dano que recebe | 🆕 Contra-ataque |
| **Iniciador** | Avança vários hexágonos de uma vez e abre a luta | 🆕 Avanço |

### O segundo eixo

Vale para qualquer papel e vai junto do nome:

- **Físico, especial ou misto:** misto quando o Ataque e o Ataque Especial ficam a menos de 15 um do outro. Para o Guardião, a defesa que ele cobre.
- **Velocidade:** rápido (100 ou mais), médio (61 a 99) ou lento (60 ou menos).

Exemplo: "Atacante Canhão especial, lento, com Arquiteto de secundário".

## Regras para toda linha nova

1. **A spec da linha declara** o papel principal (família e subpapel), o secundário e o segundo eixo da forma final, no README dela, em "Decisões".
2. **O papel não mora só nas Técnicas.** Cada Ecobeast usa no máximo 3 Técnicas na luta, então o papel vem de três lugares juntos:
   - os **atributos** da forma final, na regra da família;
   - o **Traço**, que pode carregar o papel (um Traço passivo que cura os aliados vizinhos, por exemplo);
   - as **3 melhores Técnicas do learnset**, que precisam combinar com o papel. Um Controlador cujas 3 melhores são de dano não é Controlador.
3. **Todo subpapel ✅ tem pelo menos uma linha Comum**, para o jogador conhecer cada jeito de lutar no começo do jogo. Os raros e épicos fazem o mesmo papel com um toque diferente.
4. **A distribuição alvo das formas finais:** Atacante perto de 30%, Lutador 20%, Guardião 15%, Suporte 15%, Controlador 15% e híbridos 5%. A `catalog-balance` mede a distância até ela.
5. **Subpapel 🆕 só entra numa linha** depois da iniciativa que cria a regra dele; até lá, a linha usa o subpapel ✅ mais perto.

## Os papéis de hoje

As formas finais em 2026-11-22, pelos atributos e pelas Técnicas do banco. Quando a spec da linha diz outra coisa, vale ela, e a diferença fica anotada.

| Forma final | Papel principal | Secundário | Segundo eixo |
| --- | --- | --- | --- |
| Ruvaroth | Atacante Veloz | — | misto, rápido |
| Arbornix | Atacante Veloz | Suporte Curandeiro (Banho de Sol, Brotar, Jardim) | físico, rápido |
| Solantis | Atacante Veloz | — | físico, rápido |
| Umbrantis | Atacante Veloz | — | físico, rápido |
| Venomaw | Atacante (entre Veloz e Lutador) | Controlador Perturbador (veneno, Constrição) | físico, médio |
| Echofrost | Atacante Veloz | Controlador Arquiteto (Geada) | especial, rápido |
| Galecrest | Atacante Veloz | Controlador Arquiteto (Penas, Redemoinho) | especial, rápido |
| Tempestide | Atacante Veloz | Controlador Perturbador (Paralisado, Maré Elétrica) | especial, rápido |
| Noclume | Atacante Veloz | — | especial, rápido |
| Gatemoth | Atacante Veloz | Controlador Posicionador (Teleporte, Atordoado) | especial, rápido |
| Magmollusk | Atacante Canhão | — | especial, lento |
| Nilgorr | Lutador Brigão | Guardião Muralha (Casca Fechada, Muralha de Coral) | físico, médio |
| Ingot | Lutador Brigão | Controlador Arquiteto (Lamaçal, Areia Movediça) | físico, lento |
| Dunestrike | Lutador Brigão (a spec diz tanque) | Controlador Perturbador (Preso de certeza, Areia Movediça) | físico, lento |
| Prismback | Guardião Muralha | Suporte Protetor (Halo Protetor) | especial, lento |
| Pouchmend | Suporte Curandeiro | Suporte Protetor (Atadura Firme) | médio |
| Toxbloom | Guardião Muralha ([nectoad-line](../nectoad-line/README.md#papel)) | Controlador Arquiteto (Poça Tóxica, Abraço da Flor) | físico, lento |
| Blizzvolt | Controlador Perturbador (pelos atributos, seria Lutador misto) | — | misto, médio |
| Bloomarch | Controlador Arquiteto ([bumbit-line](../bumbit-line/README.md#papel); pelos atributos, seria Lutador misto) | Controlador Perturbador (Zumbido) e Enfraquecedor (Nuvem de Pólen) | especial, médio |

Contagem, com o Toxbloom e o Bloomarch: Atacante 11 de 19 (58%), Lutador 3, Guardião 2, Suporte 1, Controlador 2. Nenhuma Muralha mista, nenhum Inspirador, Enfraquecedor ou Atirador como papel principal.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| Os 5 papéis e os subpapéis acima viram a regra do projeto | "Quero que deixe em memória no projeto essas rules, vamos seguir de forma organizada" |
| Nada muda no jogo agora; as linhas novas passam a seguir a regra | "Não quero transformar nada agora, mas começar a seguir essas regras" |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| "Lutador" no lugar de "bruiser" | O vocabulário do jogo é em pt-BR |
| A distribuição alvo de 30/20/15/15/15/5 | Deixa os Atacantes como o papel mais comum sem tomar o catálogo |
| A ordem das regras novas: Reviver e Limpar estados, Provocar e Proteger aliado, Empurrar e puxar, e o resto depois | Os dois primeiros completam o Suporte e o Guardião, os papéis mais vazios; empurrar casa com as marcas que já existem |

## Fora do escopo

- Uma coluna de papel no banco ou o papel na tela do jogo (a fase 2, proposta).
- Rebalancear os Ecobeasts de hoje para chegar na distribuição alvo.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | O guia | Este README, o GDD, a skill `catalog-balance` lendo os papéis daqui | concluída |
| 2 | O papel no catálogo | As tabelas `roles` e `sub_roles` e o papel da espécie, mostrados no F1 e no Bestiário | proposta |
| 3 | O Curandeiro completo | Os efeitos Reviver e Limpar estados | proposta |
| 4 | O Guardião completo | Os efeitos Provocar e Proteger aliado | proposta |
| 5 | O Posicionador completo | Os efeitos Empurrar e Puxar | proposta |
| 6 | O resto | Escudo, Adiantar a vez, Obstáculo, Contra-ataque e Avanço | proposta |
