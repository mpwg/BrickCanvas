#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Fehler: xcodegen ist nicht installiert." >&2
  echo "Installation mit Homebrew: brew install xcodegen" >&2
  exit 1
fi

echo "Erzeuge Xcode-Projekt aus project.yml ..."
xcodegen generate
