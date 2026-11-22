# Telas do protótipo — Ecobeast

Celular, orientação retrato. Estilo fantasia leve, colorido e amigável. 15 elementos (Fogo, Água, Flora, Volt, Terra, Vento, Gelo, Metal, Toxina, Psíquico, Sombra, Luz, Instinto, Arcano, Inseto), cada um com cor e ícone próprios. Nada parecido com Pokémon.

1. **Splash / Título** — logo, botão "Jogar", ícone de configurações.
2. **Escolha do inicial** — 3 criaturas (Fogo, Água, Flora) com nome, elemento e botão "Escolher".
3. **Home (Hub)** — a primeira tela, depois de criar o Domador e escolher o inicial. Embaixo, a barra de abas, como a do Clash Royale: Loja, Refúgio, Home (no meio), Ecobeasts e Mochila, com a escolhida saltada e as telas trocando dentro do Hub. Na Home, o topo (avatar e nome, que abrem o Perfil, nível e XP do domador, moedas e a engrenagem das Configurações), o palco (o Domador e o Ecobeast em destaque em pixel art, de pé na grama da arte, com a etiqueta do nome, do nível e do HP; tocar no Ecobeast abre os detalhes), a equipe em 6 bolinhas, que trocam o destaque, e o botão grande Explorar (um mapa gerado novo) (`.specs/hub-start/`).
4. **Mapa de exploração** — mapa hexagonal gerado a cada exploração, com o jogador no centro da tela, andando um hexágono por vez, sem zoom nem arrastar. Botão provisório "Procurar Ecobeast", "Mochila" e "Voltar".
5. **Batalha** — inimigo em cima (nome, nível, elemento, HP, status); sua criatura embaixo (nome, nível, HP numérico, XP); log do turno; botões Atacar, Itens, Equipe, Correr; em Atacar, 3 técnicas em ícones com elemento (cor), PP e countdown, e segurar mostra o detalhe.
6. **Captura** — tela escurecida por cima da luta, com o Ecobeast entrando na Esfera enquanto um anel enche; depois, "Capturado!" ou "Escapou!". Sem arremesso nem tremidas.
7. **Fim de batalha** — XP, level up, moedas; pop-up de nova técnica (escolher qual esquecer); tela de evolução com botão cancelar.
8. **Detalhes da criatura** — sprite grande, nome/apelido, nível, elementos, temperamento, traço, item; gráfico de atributos (HP, Atk, Def, SpAtk, SpDef, Spd); 3 técnicas.
9. **Ecobeasts** (a Equipe) — 6 vagas: segurar e arrastar muda a ordem, e o primeiro com HP começa a luta. Mostra HP e status, e cada Ecobeast abre detalhes e a troca com o Santuário. Embaixo, os botões Santuário e Bestiário.
10. **Santuário** — grade com busca, filtro por Elemento e ordem por nível; o filtro de raridade fica para quando houver espécies de raridades diferentes. Cada Ecobeast abre detalhes e a ação de mover para a equipe.
11. **Bestiário** — grade numerada (visto, capturado, silhueta); detalhe com descrição, elementos, habitat e linha evolutiva. Visto conta só em luta, e a primeira captura de uma espécie, ou a Evolução para ela, mostra o aviso de registro (`.specs/codex/`).
12. **Loja** — uma aba por categoria (hoje Esferas e Cura; depois Itens de batalha e Evolução); cards com preço e comprar.
13. **Mochila** — itens por categoria com quantidade; escolher alvo ao usar. Abre pelo Hub e pelo mapa.
14. **Refúgio** — a equipe, com HP, PP e status, e o botão "Curar todos".
15. **Arenas** — 8 emblemas (obtidos/bloqueados), mestre de cada Arena e "Desafiar"; Liga final.
16. **Perfil / Configurações** — o Perfil mostra o Domador, o nome, o nível, as moedas e as espécies vistas e capturadas, com o botão Aparência; as Configurações têm o volume da Música e dos Sons, o Sair da conta e, em depuração, o Apagar progresso (`.specs/hub-start/02-ecobeasts-profile-settings.md`). Depois: conquistas, idioma, nuvem, remover anúncios.
17. **Aparência** — o Domador grande, que gira, e as abas Corpo, Rosto, Parte de baixo, Calçado, Parte de cima, Cabelo e Chapéu, cada uma com as peças e as cores; Salvar. Abre na entrada, com o nome, e pelo botão Aparência do Perfil (`.specs/tamer-appearance/`).
