"""Pipeline BOE → Oposiwork: procesa PDFs y genera contenido con Claude."""

import json
import argparse
from pathlib import Path
from typing import Optional
import pdfplumber
import anthropic
from supabase import create_client, Client
from dotenv import load_dotenv
import os

load_dotenv()

supabase: Client = create_client(
    os.environ["SUPABASE_URL"],
    os.environ["SUPABASE_SERVICE_KEY"],
)
claude = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

MODEL = "claude-sonnet-4-20250514"


def extraer_texto_pdf(ruta_pdf: str) -> str:
    texto = []
    with pdfplumber.open(ruta_pdf) as pdf:
        for pagina in pdf.pages:
            t = pagina.extract_text()
            if t:
                texto.append(t)
    return "\n\n".join(texto)


def generar_resumen(texto: str, numero: int, oposicion: str) -> dict:
    respuesta = claude.messages.create(
        model=MODEL,
        max_tokens=2000,
        messages=[{
            "role": "user",
            "content": f"""Eres un preparador experto de oposiciones españolas.

Analiza este Tema {numero} del temario de {oposicion} y genera:
1. RESUMEN EJECUTIVO (máximo 500 palabras, en puntos clave)
2. ARTÍCULOS CLAVE (los más preguntados, con número y ley)
3. CONCEPTOS IMPRESCINDIBLES (10 conceptos que el opositor DEBE memorizar)

Texto del tema:
{texto[:6000]}

Responde SOLO en JSON con esta estructura:
{{
  "resumen": "texto del resumen...",
  "articulos_clave": [{{"articulo": "Art. X", "ley": "Ley X/XXXX", "contenido": "..."}}],
  "conceptos": ["concepto1", "concepto2"]
}}"""
        }]
    )
    return json.loads(respuesta.content[0].text)


def generar_flashcards(texto: str, numero: int, oposicion: str) -> list[dict]:
    respuesta = claude.messages.create(
        model=MODEL,
        max_tokens=3000,
        messages=[{
            "role": "user",
            "content": f"""Genera 15 flashcards de estudio para el Tema {numero} de {oposicion}.

Cada flashcard:
- Pregunta directa y concisa
- Respuesta exacta (como en examen)
- Artículo de referencia cuando aplique

Texto:
{texto[:5000]}

Responde SOLO en JSON:
{{"flashcards": [{{"pregunta": "...", "respuesta": "...", "articulo": "..."}}]}}"""
        }]
    )
    data = json.loads(respuesta.content[0].text)
    return data["flashcards"]


def generar_preguntas_test(texto: str, numero: int, oposicion: str) -> list[dict]:
    respuesta = claude.messages.create(
        model=MODEL,
        max_tokens=4000,
        messages=[{
            "role": "user",
            "content": f"""Genera 20 preguntas de examen tipo test para el Tema {numero} de {oposicion}.

Cada pregunta:
- 4 opciones (a, b, c, d), solo una correcta
- Explicación de la respuesta correcta
- Artículo/ley de referencia
- Dificultad variada (1=fácil, 3=difícil)

Texto:
{texto[:5000]}

Responde SOLO en JSON:
{{"preguntas": [{{"enunciado": "...", "a": "...", "b": "...", "c": "...", "d": "...",
  "correcta": "a", "explicacion": "...", "articulo": "...", "dificultad": 1}}]}}"""
        }]
    )
    data = json.loads(respuesta.content[0].text)
    return data["preguntas"]


TIPOS_PSICOTECNICOS = [
    ("series_numericas", "numerico"),
    ("analogias_verbales", "verbal"),
    ("razonamiento_espacial", "espacial"),
    ("memoria_secuencial", "memoria"),
    ("atencion_selectiva", "atencion"),
]

PROMPTS_PSICOTECNICOS = {
    "series_numericas": "Genera una serie numérica con patrón lógico (aritmétic, geométrica o mixta). El opositor debe identificar el siguiente número.",
    "analogias_verbales": "Genera una analogía verbal tipo 'A es a B como C es a ___'. El opositor elige la palabra que completa la analogía.",
    "razonamiento_espacial": "Describe un ejercicio de rotación/transformación mental de figuras geométricas. Indica claramente la figura y las opciones.",
    "memoria_secuencial": "Genera un ejercicio de memoria: presenta una secuencia de palabras, números o imágenes descritas y pregunta por un elemento específico.",
    "atencion_selectiva": "Genera un ejercicio de atención: cuenta ocurrencias de un símbolo en una secuencia o detecta el elemento diferente.",
}


def generar_psicotecnicos(oposicion_id: str, cantidad_por_tipo: int = 10) -> None:
    print(f"  Generando psicotécnicos ({len(TIPOS_PSICOTECNICOS)} tipos × {cantidad_por_tipo})...")
    for subtipo, tipo in TIPOS_PSICOTECNICOS:
        prompt_base = PROMPTS_PSICOTECNICOS[subtipo]
        for dificultad in range(1, min(cantidad_por_tipo + 1, 6)):
            respuesta = claude.messages.create(
                model=MODEL,
                max_tokens=800,
                messages=[{
                    "role": "user",
                    "content": f"""{prompt_base}

Dificultad: {dificultad}/5 (1=muy fácil, 5=muy difícil)

Genera EXACTAMENTE 1 ejercicio. Responde SOLO en JSON:
{{
  "enunciado": "...",
  "opciones": ["opción A", "opción B", "opción C", "opción D"],
  "respuesta_correcta": "opción A",
  "explicacion": "..."
}}"""
                }]
            )
            try:
                data = json.loads(respuesta.content[0].text)
                supabase.table("psicotecnicos").insert({
                    "oposicion_id": oposicion_id,
                    "tipo": tipo,
                    "subtipo": subtipo,
                    "enunciado": data["enunciado"],
                    "opciones": data["opciones"],
                    "respuesta_correcta": data["respuesta_correcta"],
                    "explicacion": data.get("explicacion"),
                    "dificultad": dificultad,
                }).execute()
            except (json.JSONDecodeError, KeyError) as e:
                print(f"    Advertencia: error en psicotécnico {subtipo} dif.{dificultad}: {e}")
    print(f"  Psicotécnicos generados.")


def procesar_tema(
    tema_id: str,
    oposicion_id: str,
    texto: str,
    numero: int,
    oposicion_nombre: str,
) -> None:
    print(f"  Generando resumen...")
    resumen = generar_resumen(texto, numero, oposicion_nombre)
    supabase.table("contenido_temas").insert({
        "tema_id": tema_id,
        "tipo": "resumen",
        "contenido": resumen,
    }).execute()

    print(f"  Generando flashcards...")
    flashcards = generar_flashcards(texto, numero, oposicion_nombre)
    for fc in flashcards:
        supabase.table("flashcards").insert({
            "tema_id": tema_id,
            "pregunta": fc["pregunta"],
            "respuesta": fc["respuesta"],
            "articulo_referencia": fc.get("articulo"),
            "dificultad": 1,
        }).execute()

    print(f"  Generando preguntas de test...")
    preguntas = generar_preguntas_test(texto, numero, oposicion_nombre)
    for p in preguntas:
        supabase.table("preguntas_test").insert({
            "tema_id": tema_id,
            "oposicion_id": oposicion_id,
            "enunciado": p["enunciado"],
            "opcion_a": p["a"],
            "opcion_b": p["b"],
            "opcion_c": p["c"],
            "opcion_d": p["d"],
            "respuesta_correcta": p["correcta"],
            "explicacion": p.get("explicacion"),
            "articulo_referencia": p.get("articulo"),
            "dificultad": p.get("dificultad", 1),
        }).execute()

    print(f"  Tema {numero} procesado correctamente.")


def main():
    parser = argparse.ArgumentParser(description="Procesa PDFs del BOE para Oposiwork")
    parser.add_argument("--oposicion", required=True, help="Slug de la oposición")
    parser.add_argument("--pdf", help="Ruta al PDF del temario")
    parser.add_argument("--tema", type=int, help="Número de tema específico (opcional)")
    parser.add_argument(
        "--permitir-texto-minimo",
        action="store_true",
        help="Permite generar contenido usando solo título de tema. No usar en producción.",
    )
    args = parser.parse_args()

    # Obtener oposición
    result = supabase.table("oposiciones")\
        .select("id, nombre, tiene_psicotecnicos")\
        .eq("slug", args.oposicion)\
        .single()\
        .execute()

    if not result.data:
        print(f"Error: oposición '{args.oposicion}' no encontrada")
        return

    oposicion_id = result.data["id"]
    oposicion_nombre = result.data["nombre"]
    tiene_psicotecnicos = result.data.get("tiene_psicotecnicos", False)
    print(f"Procesando: {oposicion_nombre}")

    # Obtener temas
    temas_query = supabase.table("temas")\
        .select("id, numero, titulo")\
        .eq("oposicion_id", oposicion_id)\
        .order("numero")

    if args.tema:
        temas_query = temas_query.eq("numero", args.tema)

    temas = temas_query.execute().data

    if not temas:
        print("No se encontraron temas")
        return

    if not args.pdf and not args.permitir_texto_minimo:
        print(
            "Error: falta --pdf. No se genera contenido desde solo el título "
            "porque produciría material no verificable."
        )
        print(
            "Para pruebas locales puedes usar --permitir-texto-minimo, "
            "pero no debe usarse para contenido publicable."
        )
        return

    # Si se proporcionó PDF, extraer texto
    texto_pdf: Optional[str] = None
    if args.pdf:
        print(f"Extrayendo texto de {args.pdf}...")
        texto_pdf = extraer_texto_pdf(args.pdf)

    for tema in temas:
        print(f"\nTema {tema['numero']}: {tema['titulo']}")
        texto = texto_pdf or f"Tema {tema['numero']}: {tema['titulo']}"
        procesar_tema(
            tema_id=tema["id"],
            oposicion_id=oposicion_id,
            texto=texto,
            numero=tema["numero"],
            oposicion_nombre=oposicion_nombre,
        )

    if tiene_psicotecnicos and not args.tema:
        print("\nGenerando psicotécnicos...")
        generar_psicotecnicos(oposicion_id)

    print("\nProcesamiento completado.")


if __name__ == "__main__":
    main()
