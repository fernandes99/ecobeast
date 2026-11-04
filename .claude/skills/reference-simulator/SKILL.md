---
name: reference-simulator
description: Descobre como o simulador que inspirou o Ecobeast (o Pokémon Simulator 4.5, instalado em C:\Games\POKéGAME) calcula uma regra, como dinheiro, XP, captura, dano, evolução ou preços, lendo o código de máquina do executável sem rodá-lo. Use sempre que o usuário perguntar como "o simulador", "o Simulator", "o jogo original" ou "a referência" faz alguma coisa, pedir para consultar, encontrar ou comparar um algoritmo ou fórmula com ele, ou quando uma regra nova do Ecobeast for decidida e o dono quiser saber como a referência resolvia.
---

# Algoritmos do simulador de referência

O Ecobeast é inspirado no Pokémon Simulator 4.5 (Birdiesoft), um programa em Delphi para Windows. O código-fonte não existe: a regra está compilada em `C:\Games\POKéGAME\PokeGame.exe`. Esta skill acha a regra lendo o executável como dado. Fale com o dono em pt-BR.

## Regras

- **Nunca rode** nada da pasta do jogo, nem o atualizador ou o desinstalador. Só leitura.
- Saídas temporárias vão para o scratchpad da sessão, nunca para o repositório.
- O que vem da referência é a **mecânica**. Nomes, textos e visuais não entram no jogo: a regra é traduzida para o vocabulário de `.specs/glossary.md`, e a decisão final é do dono.
- Diga ao dono o que foi **confirmado** pelo código e o que foi **deduzido**.

## Antes de tudo

Leia [references/findings.md](references/findings.md). Se a pergunta já foi respondida, responda dali, sem desmontar nada.

## Ambiente

O script usa `capstone` e `pefile`, num ambiente Python fora do projeto. `PY` é `"$LOCALAPPDATA/ecobeast-simref/venv/Scripts/python"`, e `S` é `.claude/skills/reference-simulator/scripts/simref.py`. Confira com `$PY -I -c "import capstone, pefile"`. Se falhar, crie de novo:

```bash
VENV="$LOCALAPPDATA/ecobeast-simref/venv"
rm -rf "$VENV" && python -m venv "$VENV" && "$VENV/Scripts/python" -m pip install -q capstone pefile
```

Rode sempre com `-I`.

## Passos

1. **Ache a mensagem do jogo** ligada à regra. A ajuda (`POKéGAME.HLP`) é comprimida, mas às vezes tem títulos úteis.
   - `$PY -I $S strings "You got|money"` lista os textos com o endereço.
   - `--file "C:/Games/POKéGAME/POKéGAME.HLP"` procura na ajuda.
2. **Ache o código que usa o texto.** `$PY -I $S refs <endereço>` costuma devolver um `push`. O endereço dele é o ponto da rotina.
3. **Desmonte em volta:** `$PY -I $S dis <endereço> --before 200 --after 100`. A linha do endereço vem marcada com `>>`. Chamadas e endereços conhecidos vêm anotados, e textos aparecem entre aspas. As primeiras linhas podem sair erradas, porque o começo é adivinhado. Confie a partir da primeira instrução que faz sentido.
4. **Leia como Delphi:**
   - Os três primeiros argumentos vão em `eax`, `edx` e `ecx`, e o retorno volta em `eax`.
   - `mov eax, N` seguido de `call 0x4030f8` é `Random(N)`.
   - As mensagens são montadas com `push` de textos e uma chamada que junta todos, e depois vão para o log.
   - Variáveis globais aparecem como `[0x4a....]`.
   - Um `add eax, 0x4a....` costuma ser acesso a um vetor, e não uma mudança na variável.
5. **Confirme o que cada variável é** procurando onde ela muda, com `$PY -I $S refs <variável>`. Uma soma logo antes de uma mensagem conhecida diz o que é, como as insígnias somando antes de "You earned the …".
6. **Responda ao dono** com a regra em passos e uma tabela de exemplos. Separe o confirmado do deduzido. Se fizer sentido para a pergunta, mostre como a regra ficaria no Ecobeast.
7. **Registre** em `references/findings.md` o que foi decifrado, com a data. Se descobriu um endereço novo, ponha também em `KNOWN`, no script, para as próximas desmontagens já virem anotadas.
