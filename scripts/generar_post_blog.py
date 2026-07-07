# Genera un borrador de post SEO para el blog de Oposiwork con Claude.
#
# Uso:
#   python scripts/generar_post_blog.py "tema del post" slug-del-post
# Ejemplo:
#   python scripts/generar_post_blog.py "Cómo aprobar el examen de ofimática de Auxiliar Administrativo" ofimatica-auxiliar-administrativo
#
# Crea web/landing/blog/<slug>/index.html siguiendo la plantilla del blog.
# Requiere ANTHROPIC_API_KEY en el entorno o en .env.
# REVISA SIEMPRE el borrador antes de desplegar: la IA redacta, tú publicas.
import json
import os
import re
import sys
import urllib.request
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent


def leer_api_key() -> str:
    clave = os.environ.get("ANTHROPIC_API_KEY", "")
    if clave:
        return clave
    env = RAIZ / ".env"
    if env.exists():
        for linea in env.read_text(encoding="utf-8").splitlines():
            if linea.startswith("ANTHROPIC_API_KEY="):
                return linea.split("=", 1)[1].strip()
    raise SystemExit("Falta ANTHROPIC_API_KEY (entorno o .env)")


def generar(tema: str) -> dict:
    prompt = f"""Eres el redactor SEO de Oposiwork, plataforma española que detecta cualquier
convocatoria de oposición (BOE + 66 boletines autonómicos y provinciales) y da material para
prepararla (tests, resúmenes, flashcards, psicotécnicos) por 9,99 €/mes.

Escribe un post de blog en castellano sobre: {tema}

Requisitos:
- 500-800 palabras, tono claro y directo, sin humo.
- Estructura: intro breve con gancho + 3-4 secciones con h2 + cierre con CTA.
- Consejos accionables reales, no relleno.
- Menciona de forma natural (sin forzar) cómo ayuda Oposiwork, sobre todo las
  alertas por provincia y que se puede estudiar en la misma app.
- No inventes cifras oficiales ni fechas de convocatorias concretas.

Responde SOLO con JSON válido:
{{"titulo_seo": "max 60 chars", "descripcion": "max 155 chars",
  "titulo_h1": "...", "cuerpo_html": "<p>...</p><h2>...</h2>... (sin h1, sin html/head/body)"}}"""

    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps({
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 2500,
            "messages": [{"role": "user", "content": prompt}],
        }).encode(),
        headers={
            "x-api-key": leer_api_key(),
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=90) as r:
        data = json.loads(r.read().decode())
    texto = data["content"][0]["text"]
    return json.loads(texto[texto.find("{"):texto.rfind("}") + 1])


PLANTILLA = """<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{titulo_seo} - Oposiwork</title>
  <meta name="description" content="{descripcion}">
  <meta name="robots" content="index, follow, max-image-preview:large">
  <link rel="canonical" href="https://www.oposiwork.com/blog/{slug}/">
  <link rel="stylesheet" href="/styles.css">
  <script type="application/ld+json">
  {{
    "@context": "https://schema.org",
    "@type": "Article",
    "headline": "{titulo_h1}",
    "datePublished": "{fecha}",
    "author": {{ "@type": "Organization", "name": "Oposiwork" }},
    "publisher": {{ "@type": "Organization", "name": "Oposiwork", "url": "https://www.oposiwork.com/" }},
    "mainEntityOfPage": "https://www.oposiwork.com/blog/{slug}/"
  }}
  </script>
</head>
<body>
  <header class="site-header">
    <a class="brand" href="/"><img src="/icons/Icon-192.png" alt="">Oposiwork</a>
    <nav class="nav-links"><a href="/blog/">Blog</a><a href="/app/login" class="button primary">Entrar</a></nav>
  </header>
  <main class="section legal-page">
    <article class="legal-card">
      <h1>{titulo_h1}</h1>
      {cuerpo}
      <p><a class="button primary" href="/app/login?utm_source=blog&utm_medium=post&utm_campaign={slug}">Empezar gratis en Oposiwork</a></p>
    </article>
  </main>
  <script defer src="/cookies.js"></script>
</body>
</html>
"""


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit('Uso: python scripts/generar_post_blog.py "tema" slug-del-post')
    tema, slug = sys.argv[1], sys.argv[2]
    if not re.fullmatch(r"[a-z0-9-]{3,80}", slug):
        raise SystemExit("Slug inválido: usa minúsculas, números y guiones")

    destino = RAIZ / "web" / "landing" / "blog" / slug / "index.html"
    if destino.exists():
        raise SystemExit(f"Ya existe {destino}")

    post = generar(tema)
    destino.parent.mkdir(parents=True, exist_ok=True)
    destino.write_text(
        PLANTILLA.format(
            titulo_seo=post["titulo_seo"][:60],
            descripcion=post["descripcion"][:155],
            titulo_h1=post["titulo_h1"],
            cuerpo=post["cuerpo_html"],
            slug=slug,
            fecha=date.today().isoformat(),
        ),
        encoding="utf-8",
    )
    print(f"Borrador creado: {destino}")
    print("Recuerda: 1) revisar el texto, 2) añadir tarjeta en blog/index.html,")
    print("3) añadir la URL en api/sitemap.js, 4) build + deploy.")


if __name__ == "__main__":
    main()
