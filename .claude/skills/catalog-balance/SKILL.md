---
name: catalog-balance
description: Monta o retrato do catálogo de Ecobeasts por Elemento, papel na luta (suporte, tanque, atacante físico, atacante especial, bruiser), bioma, parte do dia e raridade, acha o que falta e recomenda a próxima linha evolutiva. Use sempre que o dono pedir resumo, catálogo, balanço ou lacunas dos Ecobeasts, perguntar qual Ecobeast criar a seguir, ou antes de planejar qualquer linha nova (uma `<nome>-line`), mesmo que ele já traga a ideia pronta, para dizer o que ela cobre e o que ainda falta.
---

# Balanço do catálogo de Ecobeasts

Fale com o dono em pt-BR. Esta skill só lê o banco e responde; não cria arquivo nem spec.

## 1. Ler o catálogo de verdade

O `server/prisma/seed-data/species.json` está velho (só as 9 primeiras espécies). A fonte é o banco:

```powershell
cd server; node ../.claude/skills/catalog-balance/scripts/catalog_report.mjs
```

O script imprime, em markdown: as linhas (formas, Elementos, raridade, papel da forma final, biomas e partes do dia da base), a contagem por Elemento (como 1º Elemento da base, em alguma forma, e as Técnicas Física/Especial/Suporte daquele Elemento), por papel, por bioma (linhas cuja base nasce lá e a soma das taxas) e por raridade.

O papel é uma primeira proposta pelos atributos da forma final. Confira com a spec da linha (`.specs/<nome>-line/README.md`): se a spec diz "tanque" e o script diz "Bruiser", use a palavra da spec e diga a diferença.

| Papel | Como o script decide (forma final) |
|---|---|
| Tanque físico / especial | (HP + Def) / 2 ou (HP + Def Esp) / 2 pelo menos 15 acima do maior ataque |
| Suporte | Tanque com 40% ou mais das Técnicas de Suporte |
| Bruiser | aguenta quase tanto quanto bate (até 10 abaixo do maior ataque) |
| Atacante físico / especial / misto | o resto; misto se Ataque e Ataque Esp ficam a menos de 15 |
| rápido / médio / lento | Velocidade ≥ 100 / no meio / ≤ 60 |

## 2. Achar as lacunas

Olhe estes eixos, nesta ordem, e anote o que está em 0 ou 1:

1. **Elemento como 1º da base**: Elemento que nunca abre uma linha (só aparece como 2º numa evolução) é a maior lacuna, porque o jogador não consegue ter um puro dele.
2. **Papel**: papel com 0 formas finais, e papel saturado (um terço ou mais das linhas). Papéis a buscar além dos do script: controle (espalha estados e marcas), atacante especial lento (canhão), tanque misto, segundo suporte.
3. **Bioma**: bioma com 0 ou 1 linha de base nativa, ou soma de taxas baixa. Montanha, Água profunda, Geleira e Vulcão costumam ficar para trás; Lava rasa e Lava funda bloqueiam o andar, então só contam se a regra de nascer nelas existir.
4. **Raridade**: falta de Comum deixa o começo do jogo pobre; Ancestral fica para quando houver a regra.
5. **Técnicas do Elemento**: Elemento com 0 em alguma categoria (Física, Especial ou Suporte) pede uma linha que justifique criar essas Técnicas.
6. **Parte do dia**: conferir que cada bioma tem quem nasça em cada uma das 4 partes.

## 3. Recomendar a próxima linha

Monte 3 candidatas, cada uma uma combinação de Elemento(s), papel, biomas, partes do dia e raridade. Dê a cada uma um ponto por lacuna que ela fecha (eixos do passo 2) e tire um ponto por eixo que ela satura ainda mais. Recomende a de maior nota e diga em uma linha por que as outras perderam.

Para cada candidata, entregue:

- Elementos de cada forma e quantas formas (2 ou 3; dividir em ramos como o Prayling só se tiver um motivo).
- Papel e o perfil de atributos da forma final (os 6 valores e o total, na faixa das finais de hoje: 470 a 535 para 2 formas e 520 a 535 para 3; total maior só para raridade maior).
- Biomas com taxa, zonas que dobram ou cortam, partes do dia, raridade e crescimento.
- Uma ideia de animal e de temperamento próprio, diferente dos que já existem (cada Ecobeast tem personalidade; fofo pode, mas não todos).
- As lacunas que fecha.

Regras que valem para qualquer proposta: vocabulário de `.specs/glossary.md`, nada de nome ou visual de Pokémon, nomes de Ecobeast que não são português e se entendem em qualquer país (podem juntar duas palavras), ids novos depois do maior id que o script mostra.

## Erros comuns

- Ler o `species.json` do seed em vez do banco: perde quase todas as linhas.
- Contar a base e a forma final como duas linhas: o papel é da forma final, o bioma e a raridade são da base.
- Recomendar um Elemento que já é 1º de outra linha enquanto há Elemento em 0.
- Propor mais um atacante especial rápido sem dizer que é o papel mais cheio.
