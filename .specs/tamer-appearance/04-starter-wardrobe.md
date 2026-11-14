# 04. O primeiro guarda-roupa

- **Status:** concluída
- **Depende de:** [03-appearance-screen](03-appearance-screen.md)

## Contexto

Com a tela Aparência pronta (fase 3), falta o que escolher. Esta fase traz o corpo feminino de verdade, as primeiras peças e as paletas, e faz o visualizador (F1) listar as folhas que faltam.

## Escopo

- A arte dos 2 corpos e das peças abaixo, desenhada no formato do [architecture](architecture.md#a-arte): o corpo feminino sobre o masculino do template da Eris Esra, e as peças por cima dos dois.
- As linhas no catálogo, por migration.
- No visualizador (F1), as peças e os corpos com as folhas que faltam.

O conteúdo inicial (_a revisar_, o dono troca pelo painel):

| Lugar | Peças |
| --- | --- |
| Rosto | Rosto 1, Rosto 2 |
| Cabelo | Curto, Espetado (com `_short`), Rabo de cavalo (com `_back`), Comprido (com `_back` e `_short`) |
| Chapéu | Boné (`top`), Chapéu de palha (`top`), Capacete (`all`) |
| Parte de cima | Camiseta, Jaqueta, Regata |
| Parte de baixo | Calça, Bermuda, Saia (só Feminino) |
| Calçado | Tênis, Bota |

| Tipo | Paletas |
| --- | --- |
| Pele | 6 tons, do mais claro ao mais escuro |
| Cabelo | Preto, Castanho, Ruivo, Loiro, Branco, Azul, Verde, Rosa |
| Roupa | Vermelho, Laranja, Amarelo, Verde, Azul, Roxo, Rosa, Preto, Cinza, Branco |

## Fora do escopo

- Peças que se ganham ou se compram.

## Requisitos

- **RF-01:** Cada peça da tabela tem `idle.png` e `run.png` no formato do corpo; as marcadas, as folhas `_back` ou `_short`.
- **RF-02:** As peças e as paletas entram no catálogo pela migration `starter_wardrobe`, com os dados em `server/prisma/seed-data/`.
- **RF-03:** O visualizador (F1) lista cada corpo e cada peça, com a prévia e as folhas que faltam.
- **RF-04:** `res://assets/tamer/CREDITOS.md` cita a origem e a licença de cada folha.

## Critérios de aceite

- [x] A tela Aparência mostra todas as peças e paletas da tabela.
- [ ] Nenhuma peça vaza pelos lados de outra em nenhuma das 5 direções, parada e correndo (conferido numa prévia de 7 combinações; a conferência peça por peça fica para o dono).
- [x] O visualizador não lista nenhuma folha faltando.

## Desenho técnico

- A arte em `res://assets/tamer/bodies/` e `parts/`, gerada pelo `res://assets/tamer/make_wardrobe.gd` sobre o template (da pasta `client/`: `godot --headless -s res://assets/tamer/make_wardrobe.gd`). É provisória: o dono redesenha por cima no mesmo formato, e o gerador pode ser rodado de novo enquanto isso não acontece. O Espetado ganhou `_short`, porque os espetos vazavam pelo boné.
- A migration `20261128000002_starter_wardrobe` e os JSON de `seed-data` (peças 2 a 17 e paletas 4 a 24, com ids estáveis).
- `res://tools/content_viewer/`: na aba Geral, os corpos e as peças, cada uma com as folhas e as que faltam (`ContentFiles.tamer_files` e `appearance_part_files`).

## Verificação

- `npm run test:e2e` (o catálogo com as linhas novas).
- O projeto abre no editor sem erros nem avisos de script.
- Passos manuais (F5): vestir cada peça em cada corpo e girar pelas direções.

## Tarefas

- [x] O corpo feminino, com a mesma silhueta e a mesma pose do masculino (provisório, por código).
- [x] As peças, por código, sobre o template.
- [x] A migration e os dados.
- [x] O visualizador.
