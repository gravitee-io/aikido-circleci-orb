#!/usr/bin/env bash
set -euo pipefail

echo "Dry run: pulling scanner image and printing help (no API key required, no scan performed)."
docker run --rm "aikidosecurity/local-scanner:${PARAM_SCANNER_VERSION}" image-scan --help
