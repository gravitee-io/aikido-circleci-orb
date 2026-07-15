#!/usr/bin/env bash
set -euo pipefail

# The API key parameter is an env_var_name; resolve it indirectly.
API_KEY="${!PARAM_API_KEY:-}"
if [ -z "${API_KEY}" ]; then
  echo "ERROR: Aikido API key env var (\$${PARAM_API_KEY}) is not set or empty."
  echo "Add it as a CircleCI project or context environment variable."
  exit 1
fi

if [ -z "${PARAM_IMAGE:-}" ] && [ -z "${PARAM_IMAGE_FILE:-}" ]; then
  echo "ERROR: no image provided (set docker_image_to_scan or built_docker_image_file)."
  exit 1
fi

# Build optional flags.
FAIL_ARG=""
if [ -n "${PARAM_FAIL_ON:-}" ]; then
  FAIL_ARG="--fail-on ${PARAM_FAIL_ON}"
fi

scan_one() {
  local image="$1"
  echo "Scanning image: ${image}"
  echo "Scanner: aikidosecurity/local-scanner:${PARAM_SCANNER_VERSION}"
  [ -n "${FAIL_ARG}" ] && echo "Gating: ${FAIL_ARG}"

  # shellcheck disable=SC2086
  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    "aikidosecurity/local-scanner:${PARAM_SCANNER_VERSION}" \
    image-scan "${image}" \
    --apikey "${API_KEY}" \
    ${FAIL_ARG} ${PARAM_EXTRA_ARGS:-}
}

if [ -n "${PARAM_IMAGE:-}" ]; then
  scan_one "${PARAM_IMAGE}"
else
  if [ ! -f "${PARAM_IMAGE_FILE}" ]; then
    echo "ERROR: built_docker_image_file not found: ${PARAM_IMAGE_FILE}"
    exit 1
  fi
  while IFS="" read -r image || [ -n "$image" ]; do
    [ -z "${image}" ] && continue
    scan_one "${image}"
  done < "${PARAM_IMAGE_FILE}"
fi
