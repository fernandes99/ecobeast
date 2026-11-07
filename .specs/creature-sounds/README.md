# Creature sounds

Cada Ecobeast tem um som característico, só dele, que mais tarde toca quando o Domador o seleciona ou quando ele entra na luta.

## Contexto

O jogo não tinha nenhum som de Ecobeast: só os de dano (`res://assets/sounds/hits/`) e o da Técnica Arranhão. O dono quer que cada Ecobeast tenha o seu som, "o som característico dele", e desistiu do som de derrota. Os sons ainda vão ser feitos, então a primeira entrega organiza onde cada um mora e mostra no visualizador de conteúdo quem já tem. Por enquanto o jogo fica em silêncio.

## Decisões

| Decisão | Motivo |
| --- | --- |
| Um som por espécie, também para cada Evolução | Pedido do dono: "cada ecobeast vai ter seu som" |
| Sem som de derrota | O dono desistiu dele |
| O arquivo é `res://assets/creatures/<slug>/call.wav`, ao lado do `front.png` | O nome em inglês, como os outros arquivos da pasta, a pedido do dono. `call`, e não `cry`, porque "cry" é o termo do Pokémon para isso (decisão de Claude, aceita pelo dono) |
| `.wav`, como os sons das Técnicas e de dano | Um formato só para os sons do jogo |
| Na fase 01, o som não toca em nenhum lugar do jogo | Pedido do dono: "por enquanto fica em silencio" |
| O dono manda os sons; nenhum é gerado | Como os ícones das Técnicas |

## Fora do escopo

- Tocar o som no jogo (ao selecionar, ao entrar na luta e onde mais o dono decidir): é a próxima fase, ainda sem spec.
- Som de derrota.
- O som do Domador.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-call-files](01-call-files.md) | O lugar do `call.wav` e a linha "call" no visualizador de conteúdo | concluída (falta o dono ver) |
