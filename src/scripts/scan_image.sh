#!/usr/bin/env bash
set -euo pipefail

if [ "${PARAM_DRY_RUN:-false}" = "true" ]; then
  echo "Dry run: pulling scanner image and printing help (no API key required, no scan performed)."
  docker run --rm "aikidosecurity/local-scanner:${PARAM_SCANNER_VERSION}" image-scan --help
  exit 0
fi

# The API key parameter is an env_var_name; resolve it indirectly.
API_KEY="${!PARAM_API_KEY:-}"
if [ -z "${API_KEY}" ]; then
  echo "ERROR: Aikido API key env var (\$${PARAM_API_KEY}) is not set or empty."
  echo "Add it as a CircleCI project or context environment variable."
  exit 1
fi

if [ -z "${PARAM_IMAGE:-}" ]; then
  echo "ERROR: no image provided (docker_image_to_scan)."
  exit 1
fi

# Build optional flags.
FAIL_ARG=""
if [ -n "${PARAM_FAIL_ON:-}" ]; then
  FAIL_ARG="--fail-on ${PARAM_FAIL_ON}"
fi

echo "Scanning image: ${PARAM_IMAGE}"
echo "Scanner: aikidosecurity/local-scanner:${PARAM_SCANNER_VERSION}"
[ -n "${FAIL_ARG}" ] && echo "Gating: ${FAIL_ARG}"

# shellcheck disable=SC2086
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  "aikidosecurity/local-scanner:${PARAM_SCANNER_VERSION}" \
  image-scan "${PARAM_IMAGE}" \
  --apikey "${API_KEY}" \
  ${FAIL_ARG} ${PARAM_EXTRA_ARGS:-}
