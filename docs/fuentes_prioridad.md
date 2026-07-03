# Fuentes de convocatorias — Plan priorizado de mejora

> Base: auditoría en vivo (`fuente_auditoria`, últimas 72 h) + sondeo real de feeds RSS/Atom
> de cada boletín (junio 2026). Prioridad por **volumen de opositores ≈ población** y por
> el peso de las oposiciones autonómicas (sanidad, educación, administración general).

## Estado actual (resumen)
- El cron corre a diario. De ~75 fuentes: **~9 OK**, ~20 `sin_resultados`, ~45 `error`.
- Causa principal de los `error`: bloqueo de WAF por User-Agent no-navegador y timeouts.
- Causa de `sin_resultados`: el sitio responde pero el parser HTML genérico no extrae items.

## Stage 0 — Desplegar lo ya hecho y RE-AUDITAR (antes de tocar nada más)
Los fixes ya aplicados en `monitor-boe` cambian el panorama:
- **BOE** → API de datos abiertos (sección 2B). Pasará de `sin_resultados` a OK.
- **UA de navegador + timeout 15s + 1 reintento** → previsiblemente recupera varias fuentes
  que daban `error` por bloqueo (p. ej. **BOP Barcelona**, cuyo RSS es válido pero erraba).

➡️ **Acción:** `supabase functions deploy monitor-boe`, esperar al cron / ejecutarlo, y volver
a mirar `fuente_auditoria`. Muchos `error` se resolverán solos; prioriza el resto con esta lista.

---

## Tier 1 — Boletines autonómicos (máximo volumen: sanidad, educación, admón.)
Ordenados por población. "Feed" = resultado del sondeo real de RSS/Atom.

| # | CCAA (pobl. aprox) | Boletín | Estado hoy | Feed RSS/Atom | Acción recomendada |
|---|---|---|---|---|---|
| 1 | Andalucía 8,6M | BOJA | ✅ OK (9) | XML sección s53 (en uso) | Mantener |
| 2 | Cataluña 8,0M | DOGC | ⚠️ sin_resultados | ❌ no expone RSS | **API/parser propio** (alta prioridad) |
| 3 | Madrid 7,0M | BOCM | ✅ OK (20) vía RSS | ✅ `bocm.es/boletines.rss` | Mantener + **dedupe** (ver Limpieza) |
| 4 | C. Valenciana 5,3M | DOGV | ⚠️ sin_resultados | ❌ no expone RSS | **API/parser propio** (alta prioridad) |
| 5 | Galicia 2,7M | DOG | ✅ OK (1) | (HTML) | Mantener; revisar bajo recall |
| 6 | Castilla y León 2,4M | BOCYL | ❌ error | ❌ no expone RSS | Parser propio / open-data JCyL |
| 7 | País Vasco 2,2M | BOPV | ✅ OK (3) | (HTML) | Mantener |
| 8 | Canarias 2,2M | BOC | ⚠️ sin_resultados | ❌ no expone RSS | Parser propio |
| 9 | Castilla-La Mancha 2,1M | DOCM | ✅ OK (3) | (HTML) | Mantener |
| 10 | Murcia 1,6M | BORM | ⚠️ sin_resultados | ❌ no expone RSS | Parser propio |
| 11 | Aragón 1,35M | BOA | ⚠️ sin_resultados | ❌ no expone RSS | Parser propio / open-data Aragón |
| 12 | Baleares 1,2M | BOIB | ⚠️ sin_resultados | ✅ **`caib.es/.../indexrss.do`** | **Migrar a RSS (quick win)** |
| 13 | Extremadura 1,05M | DOE | ⚠️ sin_resultados | ✅ **`doe.juntaex.es/rss/rss.php`** | **Migrar a RSS (quick win)** |
| 14 | Asturias 1,0M | BOPA | ⚠️ sin_resultados | ❌ | Parser propio |
| 15 | Navarra 0,67M | BON | ❌ error | ❌ (tiene open-data API) | API open-data Navarra |
| 16 | Cantabria 0,59M | BOC Cantabria | ❌ error | ❌ | Parser propio |
| 17 | La Rioja 0,32M | BOR | ❌ error | ❌ | Parser propio |
| 18 | Ceuta / Melilla ~0,08M | BOCCE / BOME | ❌ error | ❌ | Baja prioridad |

**Quick wins inmediatos (Tier 1):** migrar **Baleares (BOIB)** y **Extremadura (DOE)** a sus RSS
confirmados — cambio de 1 línea (URL + `tipo='rss'`) en el catálogo `boletines`.

---

## Tier 2 — Diputaciones / BOP provinciales (ayuntamientos + diputaciones)
En España los ayuntamientos y diputaciones publican en el **BOP de su provincia**; cubrir el BOP
cubre a todos sus municipios. Ordenado por población provincial.

| # | Provincia (pobl.) | BOP | Estado hoy | Feed | Acción |
|---|---|---|---|---|---|
| 1 | Madrid 7,0M | (usa BOCM) | — | ✅ RSS | Cubierto por BOCM |
| 2 | Barcelona 5,8M | BOPB (diba) | ❌ error | ✅ **RSS válido** `bop.diba.cat/.../feed` | **Lo arregla el fix de UA** — verificar tras deploy |
| 3 | Valencia 2,6M | BOP València (dival) | ⚠️ sin_resultados | ❌ | Parser propio |
| 4 | Sevilla 2,0M | BOP Sevilla | ⚠️ sin_resultados | ❌ | Parser propio |
| 5 | Alicante 1,95M | BOP Alicante | ❌ error | ❌ | Parser propio |
| 6 | Málaga 1,75M | BOP Málaga | ✅ OK (4) | (HTML) | Mantener (referencia de parser) |
| 7 | Murcia 1,55M | (usa BORM) | — | — | Cubierto por BORM |
| 8 | Cádiz 1,25M | BOP Cádiz | ❌ error | ❌ | Parser propio |
| 9 | Vizcaya 1,15M | BOB Bizkaia | ❌ error | ❌ | Parser propio |
| 10 | A Coruña 1,13M | BOP A Coruña | ⚠️ sin_resultados | ❌ | Parser propio |
| 11 | Las Palmas 1,13M | BOP Las Palmas | ⚠️ sin_resultados | ❌ | Parser propio |
| 12 | S.C. Tenerife 1,08M | BOP Tenerife | ⚠️ sin_resultados | ❌ | Parser propio |
| 13 | Zaragoza 0,98M | BOP Zaragoza | ❌ error | ❌ | Parser propio |
| 14 | Pontevedra 0,95M | BOPPO | ⚠️ sin_resultados | ❌ | Parser propio |
| 15 | Granada 0,93M | BOP Granada | ❌ error | ❌ | Parser propio |
| … | resto provincias | — | mayoría sin_resultados/error | ❌ | Tier 3 (parser por plataforma) |

**Estrategia eficiente para BOPs:** muchos comparten la misma plataforma de software. En vez de
50 parsers, hacer **1 parser por plataforma** y reutilizarlo:
- Plataforma tipo *Diputación* (dipuFACIL/eBOP) — agrupa varias provincias.
- BOP Málaga (que SÍ funciona) sirve de plantilla del parser HTML.

---

## Tier 3 — Resto de provincias pequeñas
Misma técnica de "1 parser por plataforma". Prioridad baja hasta cubrir Tier 1 y Tier 2.

---

## Limpieza necesaria (independiente de prioridad)
Hay **fuentes duplicadas** porque el monitor combina el catálogo de BD (`boletines`) con la lista
fija del código (`FUENTES_BASE`). Conviven dos entradas para el mismo territorio con URL distinta:
- Madrid: "Boletín Oficial de la Comunidad de Madrid" (HTML, falla) **y** "BOCM - Ultimos boletines" (RSS, OK).
- Cataluña: "Diari Oficial...Catalunya" (HTML) **y** "DOGC - Catalunya" (HTML).
- Barcelona: "BOP Barcelona" (HTML, error) **y** "BOP Barcelona - Boletin del dia" (RSS, OK).

➡️ Dejar **solo la variante RSS** que funciona y desactivar (`activo=false`) la HTML duplicada,
para reducir ruido y peticiones.

---

## Orden de ejecución sugerido
1. **Stage 0**: desplegar `monitor-boe` (BOE API + UA/retry) y re-auditar. *(0 esfuerzo extra)*
2. **Quick wins**: migrar BOIB (Baleares) y DOE (Extremadura) a RSS; dedupe Madrid/Cataluña/Barcelona. *(catálogo)*
3. **Tier 1 grandes sin feed**: parsers/API para **Cataluña (DOGC)** y **C. Valenciana (DOGV)** — máximo volumen.
4. **Tier 1 resto**: CyL, Canarias, Murcia, Aragón, Asturias, Navarra.
5. **Tier 2**: verificar Barcelona tras deploy; parsers para Valencia, Sevilla, Alicante, Cádiz, Bizkaia.
6. **Tier 3 + limpieza continua**.
