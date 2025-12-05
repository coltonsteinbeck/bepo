#!/bin/bash
# Quick start Bepo (no deploy) - alias for start-bepo.sh --quick
# For full start with deploy, use: ./scripts/start-bepo.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/start-bepo.sh" --quick
