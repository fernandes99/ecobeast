# 02. Ecobeasts, Perfil e Configurações

- **Status:** proposta
- **Depende de:** [01-hub](01-hub.md), [team-and-storage](../team-and-storage/), [codex](../codex/) e [tamer-appearance](../tamer-appearance/)

## Contexto

O Hub da [fase 1](01-hub.md) abre a Equipe de hoje pelo ícone Ecobeasts, um placeholder pelo nome e outro pela engrenagem. Esta fase faz as três telas que o dono pediu ou que o Hub pede ([README](README.md)).

## Escopo

- `client/screens/team/` (a Equipe vira a tela Ecobeasts).
- As telas novas `client/screens/profile/` e `client/screens/settings/`, com as rotas no `Router`.
- `client/screens/hub/profile_debug_panel.*`, que sai depois de as Configurações herdarem os botões.

## Requisitos

**A tela Ecobeasts**

- **RF-01:** A tela Equipe passa a se chamar **Ecobeasts** no título. Ela continua mostrando e reordenando os 6 da equipe, como hoje.
- **RF-02:** Ela ganha dois botões, lado a lado, embaixo da lista: **Santuário** (`storage`) e **Bestiário** (`codex`), abertos com `Router.push`.
- **RF-03:** O resto da tela não muda: o detalhe, guardar no Santuário e o líder.

**O Perfil**

- **RF-04:** A tela **Perfil**, aberta pelo avatar e pelo nome do Hub, mostra:
  - o Domador desenhado com a aparência dele, como na tela Aparência;
  - o nome, o nível e as moedas;
  - quantas espécies foram vistas e capturadas no Bestiário.
- **RF-05:** O botão **Aparência** abre a tela Aparência (`appearance`), e o Voltar dela volta ao Perfil.

**As Configurações**

- **RF-06:** A tela **Configurações**, aberta pela engrenagem do Hub, tem:
  - o volume da **Música** e o dos **Sons**, de 0 a 100%, cada um num controle deslizante que muda o barramento de áudio na hora. A Música é o barramento `Music`. Hoje só existem `Music` e `Voices`, e os outros sons tocam no `Master`; os Sons controlam as `Voices` e um barramento novo, `Sfx`, para onde vão os sons da luta, dos Ecobeasts e da tela (como montar o `Sfx` fica a cargo de quem implementar);
  - **Sair da conta**, que faz o que o botão do `ProfileDebugPanel` faz hoje;
  - **Apagar progresso**, só em depuração, com a confirmação de hoje.
- **RF-07:** Os dois volumes ficam guardados no aparelho (em `user://`) e valem desde a abertura do app.
- **RF-08:** O placeholder do Perfil com o `ProfileDebugPanel` sai.

## Fora do escopo

- Trocar o nome do Domador (o `PUT /v1/me/name` dá o nome uma vez).
- O idioma, as notificações e a conta do Google nas Configurações.
- Medalhas, tempo de jogo ou estatísticas no Perfil.

## Critérios de aceite

- [ ] O ícone Ecobeasts abre a tela Ecobeasts, e os botões dela abrem o Santuário e o Bestiário.
- [ ] O nome do Hub abre o Perfil, com o Domador, os números e o botão Aparência.
- [ ] A engrenagem abre as Configurações; os volumes mudam na hora e continuam depois de fechar e abrir o app.
- [ ] O Sair da conta volta ao login, e o Apagar progresso (em depuração) leva à criação do Domador.
- [ ] O jogo sem janela abre sem erro de script.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, cada tela pelo Hub.

## Tarefas

- [ ] A tela Ecobeasts.
- [ ] O Perfil.
- [ ] As Configurações e o volume guardado.
- [ ] Tirar o `ProfileDebugPanel` e o placeholder do Perfil.
- [ ] Atualizar o `CLAUDE.md`, o `TELAS.md` e o `.specs/README.md`.
- [ ] A verificação.
