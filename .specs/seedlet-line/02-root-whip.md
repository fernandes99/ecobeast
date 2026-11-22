# 02. O Chicote de Raiz no Seedlet

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-seedlet-line.md)

## Contexto

Em 2026-11-22, numa análise das Técnicas repetidas, a Bicada de Folha (58) e o Chicote de Raiz (29) apareceram quase iguais: as duas são de Flora, Físicas, de contato e alcance 1, sem efeito, com poder 40 e 45. O Chicote de Raiz não tinha quem aprendesse desde a [browt-line](../browt-line/README.md). O dono pediu: "Seedlet em vez de aprender Bicada de folha ele vai aprender Chicote de Raiz".

## Escopo

- A migração `20270215000000_seedlet_root_whip`, que troca uma linha de `species_skills`.

## Requisitos

- **RF-01:** O Seedlet (7) aprende o Chicote de Raiz (29) no nível 1 (método 1) no lugar da Bicada de Folha (58).
- **RF-02:** O Grovequill (8) e o Arbornix (9) continuam com a Bicada de Folha no nível 1, porque são aves com bico. Um Seedlet que evolui guarda o Chicote de Raiz que já sabia.

## Fora do escopo

- Os Ecobeasts já capturados que sabem a Bicada de Folha: a Técnica conhecida continua com eles.
- Mudar os números do Chicote de Raiz ou da Bicada de Folha.

## Critérios de aceite

- [x] `GET /v1/catalog` mostra o Seedlet com o Chicote de Raiz no nível 1 e sem a Bicada de Folha, e o Grovequill e o Arbornix com a Bicada.
- [x] O teste das tabelas do catálogo e o e2e do banco passam.
- [ ] Um Seedlet novo (inicial de Flora) começa com o Chicote de Raiz.
