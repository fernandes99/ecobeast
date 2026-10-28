/**
 * As duas páginas que o navegador mostra no fim do login
 * (.specs/auth-google/01-auth-server.md, RF-14), nas cores do jogo
 * (.specs/visual-theme/README.md). Textos fixos: nada vindo da URL entra aqui.
 */

function page(title: string, text: string, accent: string): string {
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} · Ecobeast</title>
<style>
  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center;
    background: #0F2337; color: #FFFFFF; font-family: system-ui, -apple-system, "Segoe UI", sans-serif; }
  main { margin: 16px; padding: 32px 24px; max-width: 360px; text-align: center;
    background: #142A43; border: 2px solid #1D4665; border-radius: 16px; }
  .logo { margin: 0 0 24px; font-size: 20px; font-weight: 900; color: #0DA4F6; }
  h1 { margin: 0 0 12px; font-size: 28px; color: ${accent}; }
  p { margin: 0; font-size: 16px; line-height: 1.5; color: #9DB7D2; }
</style>
</head>
<body>
<main>
  <p class="logo">Ecobeast</p>
  <h1>${title}</h1>
  <p>${text}</p>
</main>
</body>
</html>
`;
}

export const SUCCESS_PAGE = page(
  'Pronto!',
  'Você entrou no Ecobeast. Pode voltar ao jogo.',
  '#68C661',
);

export const ERROR_PAGE = page(
  'Não foi possível entrar',
  'Volte ao Ecobeast e tente de novo.',
  '#E5534B',
);
