# 02. O som do Ruvo

- **Status:** concluída (falta o dono ouvir)
- **Depende de:** [01-call-files](01-call-files.md)

## Contexto

Na [01](01-call-files.md), o lugar do `call.wav` ficou pronto, e a decisão era que o dono mandaria os sons. Em 2026-11-09, o dono pediu que Claude gerasse o do Ruvo: "crie agora a call.wav dele, veja algo caracteristico mas não anomalesco (igual como acontece no pokemon), e que lembre um jogo retro". Ou seja, um som sintetizado, que não imita um bicho de verdade, com cara de videogame antigo.

## Escopo

- O `res://assets/creatures/ruvo/call.wav`, gerado por um script do repositório.

## Fora do escopo

- Tocar o som no jogo: continua sem nenhuma tela que o toque.
- Os sons das outras espécies.

## Requisitos

- **RF-01:** O som é gerado por `art-source/ruvo/call.py`, em Python sem bibliotecas de fora, como os sons das Técnicas: nada gravado nem tirado de outro jogo.
- **RF-02:** Ele soa como um chip de videogame antigo: ondas quadradas de pulso, um triângulo grave por baixo, ruído de registrador (LFSR) e uma taxa de amostragem reduzida com poucos níveis de volume. Nada de latido, uivo ou ganido gravado ou imitado de perto.
- **RF-03:** O desenho (_a revisar_ pelo dono, de ouvido): duas sílabas rápidas que lembram o nome, "ru-vo", sem acento no "vo" (pedido do dono, depois de ouvir a primeira versão: "deixa mais rapido, um "ru-vo", sem muita acentuação no "vo"").
  - "ru": uma nota curta, subindo um pouco.
  - "vo": logo depois, só um pouco mais alta e no mesmo volume, com um vibrato leve e uma queda suave no fim. Sem arpejo nem salto grande.
  - Por baixo do "vo", um estalo de brasa curto, que lembra o fogo do Ruvo.
- **RF-04:** 0,34 s, 44,1 kHz, mono, 16 bits, com o pico em 70% do volume, como os outros sons.

## Critérios de aceite

- [x] O script escreve `client/assets/creatures/ruvo/call.wav`, e o Godot o importa.
- [x] No visualizador de conteúdo (F1), o Ruvo mostra "▶ Ouvir" na linha "call".
- [ ] O dono ouve e aprova o som.

## Verificação

- `python -I art-source/ruvo/call.py` e a importação no Godot.
- O volume ao longo do som, para conferir as duas sílabas no mesmo nível.
- O teste sem janela do visualizador: o Ruvo com o `call` presente.
