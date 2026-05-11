#!/usr/bin/env bash
# deploy.sh — Deploy manual de Oposiwork
# Uso: ./scripts/deploy.sh [--solo-web | --solo-functions | --solo-migraciones]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROYECTO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROYECTO_DIR"

# ── Colores ──────────────────────────────────────────────────────────────────
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
RESET='\033[0m'

ok()  { echo -e "${VERDE}✓${RESET} $*"; }
info(){ echo -e "${AMARILLO}→${RESET} $*"; }
err() { echo -e "${ROJO}✗${RESET} $*" >&2; exit 1; }

# ── Dependencias ─────────────────────────────────────────────────────────────
command -v flutter   >/dev/null 2>&1 || err "Flutter no encontrado"
command -v supabase  >/dev/null 2>&1 || err "Supabase CLI no encontrado"

# ── Flags ────────────────────────────────────────────────────────────────────
SOLO_WEB=false
SOLO_FUNCTIONS=false
SOLO_MIGRACIONES=false

for arg in "$@"; do
  case $arg in
    --solo-web)         SOLO_WEB=true ;;
    --solo-functions)   SOLO_FUNCTIONS=true ;;
    --solo-migraciones) SOLO_MIGRACIONES=true ;;
    *) err "Argumento desconocido: $arg. Usa --solo-web | --solo-functions | --solo-migraciones" ;;
  esac
done

# Si no se especifica ningún flag, ejecutar todo
if ! $SOLO_WEB && ! $SOLO_FUNCTIONS && ! $SOLO_MIGRACIONES; then
  SOLO_WEB=true
  SOLO_FUNCTIONS=true
  SOLO_MIGRACIONES=true
fi

# ── Migraciones ───────────────────────────────────────────────────────────────
if $SOLO_MIGRACIONES; then
  info "Aplicando migraciones de base de datos..."
  supabase db push --linked
  ok "Migraciones aplicadas"
fi

# ── Edge Functions ────────────────────────────────────────────────────────────
if $SOLO_FUNCTIONS; then
  info "Desplegando Edge Functions..."
  FUNCTIONS=(
    download-pdf
    verify-subscription
    chat-rag
    monitor-boe
    crear-sesion-voz
  )
  for fn in "${FUNCTIONS[@]}"; do
    info "  → $fn"
    supabase functions deploy "$fn"
  done
  ok "Edge Functions desplegadas: ${FUNCTIONS[*]}"
fi

# ── Flutter Web ───────────────────────────────────────────────────────────────
if $SOLO_WEB; then
  info "Compilando Flutter Web..."
  flutter pub get
  flutter build web --release --base-href /
  ok "Build web completado en build/web/"

  if command -v vercel >/dev/null 2>&1; then
    info "Desplegando en Vercel..."
    vercel --prod build/web/
    ok "Desplegado en Vercel"
  else
    info "Vercel CLI no instalado. Sube build/web/ manualmente o instala: npm i -g vercel"
  fi
fi

echo ""
ok "Deploy completado."
