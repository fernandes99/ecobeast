# 04. As placas do Refúgio e da Loja

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [02](02-village-objects.md)

## Contexto

Em 2026-11-20, depois dos objetos, o dono pediu, apontando as placas com símbolos do tileset: "eu quero que você crie um simbolizando o refugio, ele vai ter o simbolo de cura (+). Também crie uma placa que simbolize a loja, para a loja pode ser o genérico que tem escrita."

Claude mostrou uma prévia com a placa de escrita do pacote e o + em 4 estilos (gravado, como no pacote, vermelho, branco e verde), ao lado do prédio do Refúgio. O dono respondeu: "Coloque todas as opções, não exclua nada, apenas adicione. E deixe todas as opções disponiveis."

## Escopo

- O `make_village_objects.py` com os dois tipos novos e o ícone das placas penduradas no lugar certo.
- Os tipos de peça 129 e 130 na migração `20270111000003_village_service_signs`.

## Requisitos

- **RF-01:** O tipo 129 é `village_refuge_sign`, "Placa do Refúgio", com 4 variantes: o braço com a placa de cruz do pacote e o + gravado (1), vermelho (2, `ce3430`, o tom da cruz do prédio do Refúgio), branco (3, `f4ecdc`) e verde (4, `5cba54`). Nas variantes 2 a 4, só os pixels claros do + mudam de cor, no retângulo (4, 2) a (12, 6) do ícone.
- **RF-02:** O tipo 130 é `village_store_sign`, "Placa da Loja", com 1 variante: o braço com a placa de escrita do pacote, igual à variante 1 da Placa pendurada (122).
- **RF-03:** O ícone das placas penduradas (122, variantes 2 a 9) e das do Refúgio é o corpo da placa do pacote (16×10, sem a tampa), colado em (16, 16) do braço, por cima do corpo da placa lisa. Antes, o ícone entrava 4 px abaixo (na sombra), e a escrita da placa lisa aparecia em cima dele.
- **RF-04:** Nenhum tipo, variante ou nome de antes muda; as placas não bloqueiam nem acendem.

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra a Placa do Refúgio, com as 4 cores do + pelas teclas ← →, e a Placa da Loja.
- [ ] As placas penduradas 2 a 9 mostram só o ícone, sem a escrita por cima.
- [x] O jogo aceita o catálogo novo e carrega as 5 imagens novas.
