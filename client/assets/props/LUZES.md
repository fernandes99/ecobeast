# Luzes da noite das peças

Os pontos de luz que acendem à noite (`prop_type_lights`, [.specs/day-night/03-night-lights.md](../../../.specs/day-night/03-night-lights.md)) saem da arte pelo `find_lights.py` desta pasta:

```bash
python -I find_lights.py > ../../../server/prisma/seed-data/prop_type_lights.json
```

Como ele acha cada luz:

- **Janela:** os pixels de vidro (azul claro: `b ≥ 140`, `b − r ≥ 40`, `b ≥ g`) viram grupos, e os grupos a até 2 px um do outro viram uma janela só (as vidraças de uma mesma janela). A luz fica no centro do retângulo da janela, com o raio de metade do lado maior mais 4, entre 6 e 16 px, e a cor `ffcf70`. Um grupo com menos de 4 px num lado não é janela (as maçanetas azuis da Casa enxaimel).
- **Telhado ou parede azul:** um grupo com 20 px de largura ou 16 de altura que começa nos 45% de cima da arte não é janela.
- **Cores da mesma casa:** as variantes com a mesma silhueta (o mesmo canal alfa) só mudam de cor. Elas ficam com as luzes da que achou mais janelas, porque um telhado azul ou roxo engole a janela encostada nele.
- **Lâmpada:** os pixels amarelos (`r > 200`, `g > 150`, `b < 140`) numa faixa da arte escolhida à mão (`LAMPS`, por tipo e variante, com o raio), na cor `ffd890`. Nenhuma peça usa isso hoje: o Poste de luz e o Observatório, que usavam, saíram do jogo ([prop-cleanup](../../../.specs/prop-cleanup/)).
- **Variante 0:** quando todas as variantes têm as mesmas luzes, sai só a variante 0, que vale para todas.

O `x` e o `y` são o pixel do centro da luz a partir do pé (o meio da borda de baixo da arte: `x = coluna − largura // 2`, `y = linha − altura`). Na peça espelhada, o jogo usa a coluna `−x − 1 + largura % 2`.

**Casas da vila** (tipos 102 a 111, [village-pack](../../../.specs/village-pack/)): as janelas de vidro e a redonda do frontão; a Casinha da vila não tem janela de vidro, e fica sem luz.

**Fora do script:** o prédio do Refúgio (tipo 22) e a Casinha enxaimel (tipo 100), lidos das imagens do dono, o Altar-portal (tipo 101) e a Lanterna pendurada da vila (tipo 123, só a variante 1, acesa) têm as luzes postas à mão nas specs delas ([refuge-art](../../../.specs/refuge-art/), [timber-cottage](../../../.specs/timber-cottage/), [portal-altar](../../../.specs/portal-altar/), [village-pack](../../../.specs/village-pack/02-village-objects.md)): o vidro de uma janela pode ter o cinza da pedra, a estufa do Refúgio não acende, e as duas lanternas da vila têm a mesma silhueta, então o script daria a luz da acesa à apagada.

**Peça nova:** ponha o tipo em `TYPES` (e em `LAMPS`, se a luz for uma lâmpada amarela), rode o script e compare com o JSON de antes. As linhas novas entram no banco por uma migração, ou à mão pelo painel do Supabase.
