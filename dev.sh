#!/usr/bin/env bash
# dev.sh — Arranca Flutter con las variables de .env
# Uso: ./dev.sh [dispositivo]
# Ejemplo: ./dev.sh chrome
#          ./dev.sh macos

set -e

DEVICE="${1:-chrome}"

if [ ! -f ".env" ]; then
  echo "Error: no se encontro .env"
  echo "Copia .env.example en .env y rellena los valores."
  exit 1
fi

flutter run -d "$DEVICE" --dart-define-from-file=.env "${@:2}"
