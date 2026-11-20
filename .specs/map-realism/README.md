# map-realism

O mapa sorteado de Explorar fica mais realista:

- cada mapa tem um clima e só os biomas que combinam com ele;
- o calor muda de um lado do mapa para o outro;
- a Neve nunca fica perto da Planície, do Deserto nem da Praia;
- as montanhas e os rios saem do mesmo relevo;
- o mapa não tem buracos por dentro.

O bioma Vau sai do jogo, e os rios só se atravessam por ponte.

## Contexto

Em 2026-11-20, o dono pediu: "Agora vamos melhorar a geração do mapa explorar. Quero você veja o algoritmo inteiro hoje, e encontre pontos de melhoria, o que podemos remover e deixar mais realistico." E completou: "Um mapa não precisa ter TODOS os biomas [...] Alguns biomas não devem ser gerados proximos de outros, como por exmeplo o bioma de neve não deve ser gerado proximo de praia, planicie, deserto, e etc. O bioma 'Vau' faz sentido?"

Claude leu o gerador (`server/src/domain/exploration/map-generator.ts`, `map-water.ts` e `map-config.ts`) e gerou 6 mapas (seeds 11 a 66). Achou estes problemas:

1. **As fatias fixas.** Os ruídos de calor, de umidade e de pedra são ordenados por percentil. Assim, todo mapa tem os 12% mais quentes como Deserto, os 12% mais frios como Neve e 15% de Pedra. Os 6 mapas tinham todos os biomas.
2. **O clima em manchas.** O calor, a umidade e a pedra são três ruídos soltos, na escala miúda do terreno. A Neve e o Deserto saem em 3 ou 4 manchas cada. Por mapa, a Neve encostava na Planície de 40 a 165 vezes e na Praia de 4 a 34 vezes, porque a Praia é pintada por cima da costa gelada.
3. **O relevo partido.** As montanhas vêm de um ruído de cristas, em linhas finas pelo mapa todo. Os rios descem por outro ruído de altitude (`elevation`), que só eles usam. Por isso os rios não nascem nas montanhas, e a altitude não muda o frio. A Colina toma de 15% a 18% do mapa, em listras.
4. **Os buracos.** A borda irregular (`edgeRoughness` 200) deixa de 30 a 250 hexágonos vazios dentro do mapa.
5. **O Vau.** Sai de 0 a 13 hexágonos dele por mapa. Nenhuma ilha usa, e só o Tidebud e o Kelpcoil nascem nele.

## Objetivos

1. Um clima sorteado por mapa, com limites fixos de calor e de umidade no lugar dos percentis. Um mapa pode sair sem Neve, sem Deserto ou sem os dois.
2. O calor cai numa direção sorteada do mapa, com um ruído largo e o frio da altitude.
3. Biomas que não se encostam: a Neve só fica perto do Boreal, da Pedra, da Colina, da Montanha e da água, e a costa fria é de Pedra, não de Praia.
4. Um relevo só, de onde saem as cadeias de montanhas, as Colinas nas encostas, a Pedra em volta delas e as nascentes dos rios.
5. O mapa sem buracos e com a quantidade pedida de hexágonos.
6. Sem o Vau: as travessias dos rios são sempre pontes.

## Anti-objetivos

- Mudar o formato dos lagos: eles continuam redondos ("Eu gosto que os lagos sejam mais circulares, não mexe no formato deles").
- Mudar as ilhas já salvas. Elas guardam os próprios hexágonos, e nenhuma usa o Vau.
- Um pedaço de terra cortado por rio sem ponte.
- A Neve encostada na Planície, no Deserto ou na Praia.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| Um mapa não precisa ter todos os biomas | "Um mapa não precisa ter TODOS os biomas" |
| A Neve não fica perto da Praia, da Planície nem do Deserto | "o bioma de neve não deve ser gerado proximo de praia, planicie, deserto" |
| Seguir a proposta de Claude (os 6 pontos) | Respondeu à pergunta do Vau depois de ver a proposta |
| Tirar o Vau e deixar só pontes | "Tirar, só pontes" |
| Os lagos continuam redondos | "não mexe no formato deles" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| 4 climas: Temperado (40%), Frio (20%), Quente (20%) e Úmido (20%) | Em 60 seeds, o Frio sempre teve Neve (30% da terra), o Quente sempre teve Deserto, e metade dos Temperados e Úmidos ficou sem os dois |
| A faixa da Neve tem 2 hexágonos de Boreal em volta | "proximo" pede mais que não encostar |
| A costa fria é de Pedra | Uma costa de seixos; a Neve não encosta em areia |
| O Deserto não encosta no Boreal | A floresta fria junto da areia quente não é realista |
| A Pedra fica no alto, perto das montanhas | Um ruído solto punha pedra no meio da planície |
| O relevo mistura o ruído de altitude, as cristas e a distância até o mar | As montanhas viram cadeias, e a terra sobe para longe da costa, como já fazia a descida dos rios |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-climate-relief](01-climate-relief.md) | Clima por mapa, relevo único, vizinhanças proibidas, costa fria e mapa sem buracos | concluída (falta o dono conferir no jogo) |
| 2 | [02-no-ford](02-no-ford.md) | O Vau sai do servidor, do banco e do cliente; as travessias são só pontes | concluída (falta o dono conferir no jogo) |
