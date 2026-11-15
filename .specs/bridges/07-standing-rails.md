# 07. Os corrimãos em pé em qualquer ângulo

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [06-diagonal](06-diagonal.md)

## Contexto

Vendo uma ponte a cada 15°, o dono pediu: "não tem nenhuma maneira de evitar isso e deixar bonito? queria que tivesse ainda esse aspecto isométrico (pelo menos até o 75 graus)". A diagonal girada da [06](06-diagonal.md) tinha os corrimãos deitados no chão, e só a ponte deitada os tinha em pé.

## Requisitos

- **RF-01:** Até 75° da horizontal da tela (`HexBridges.STANDING_ANGLE`), e de 105° a 180°, a ponte tem:
  - **o piso** da vista de cima girado no ângulo dela, só o miolo, sem os corrimãos chatos; a largura repete o miolo;
  - **dois corrimãos em pé** nas bordas, como a cerca da [free-fences](../free-fences/architecture.md#o-desenho-fase-1):
    - colunas de 1 px do meio do corrimão da vista de lado, uma a cada passo da borda;
    - o poste da cabeceira, inteiro e em pé, nas duas pontas e a cada `POST_GAP` (20 px na madeira; só nas pontas na corda).
- **RF-02:** O corrimão de trás é o da borda de cima da tela, atrás de quem anda no piso; o da frente entra na ordem 6 px abaixo da borda de baixo, na frente dele.
- **RF-03:** Mais em pé que 75°, a ponte segue sendo a vista de cima, como na [05](05-width-and-cuts.md).
- **RF-04:** O piso do andar até 75° é a metade da largura menos 3 px.

Isso substitui a vista de lado assentada (05) e a diagonal girada (06).

## Critérios de aceite

- [x] Uma prévia desenhada pelo jogo mostra as duas pontes a cada 15°, de 0° a 165°, com os corrimãos em pé até 75° e depois de 105°.
- [x] Sem janela: o teste da água e do piso continua passando.
- [ ] No jogo (F5), as pontes ficam bonitas em vários ângulos.

## Desenho técnico

**Alterar:**
- `client/ui/components/hex_bridges.gd`: `_fenced`, `_deck`, `_post_of`, `BACK_RAIL` e `POST_GAP`; saem a vista de lado assentada e a diagonal girada.
