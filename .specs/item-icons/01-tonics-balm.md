# 01. Os Tônicos e o Bálsamo Puro no padrão

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [inventory-shop](../inventory-shop/) (o `ItemIcon`)

## Requisitos

- **RF-01:** `client/assets/items/light_tonic.png`, `strong_tonic.png` e `pure_balm.png` são os `Icon1.png`, `Icon13.png` e `Icon5.png` da pasta `PNG/Transperent` do pacote, sem edição.
- **RF-02:** O `ItemIcon` desenha com o filtro mais próximo os ícones de até 64 px de largura e com o linear os maiores.
- **RF-03:** Na Mochila e na Loja (o `icon_size` 96 de hoje), os ícones novos aparecem 3 vezes maiores, com todos os pixels do mesmo tamanho.

## Critérios de aceite

- [ ] Na Loja e na Mochila, os Tônicos e o Bálsamo aparecem nítidos, sem borrão.
- [x] O jogo abre sem erro de script.
