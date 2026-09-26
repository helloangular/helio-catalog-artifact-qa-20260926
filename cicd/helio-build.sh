#!/usr/bin/env bash
set -euo pipefail
: "${RESULT_FILE:?}" "${IMAGE_REPOSITORY:?}" "${REGISTRY_TOKEN:?}" "${REGISTRY_USER:?}"
[[ "$IMAGE_REPOSITORY" == "ghcr.io/${GITHUB_REPOSITORY,,}" ]]
BUILD_VERSION="$(cat VERSION)"
[[ "$BUILD_VERSION" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$ ]]
export BUILD_VERSION GO_PIPELINE_LABEL="$BUILD_VERSION" IMAGE_REPOSITORY
DOCKER_CONFIG="$(mktemp -d)"; export DOCKER_CONFIG
trap 'rm -rf -- "$DOCKER_CONFIG"' EXIT
printf '%s' "$REGISTRY_TOKEN" | docker login ghcr.io -u "$REGISTRY_USER" --password-stdin
# The converter inserts the customer's build/export tasks here. This example's
# Makefile performs an actual Docker build and push, not an echo placeholder.
if [[ -f cicd/exports.sh ]]; then
  # shellcheck source=/dev/null
  source cicd/exports.sh
fi
make build push
image="${IMAGE_REPOSITORY}:${BUILD_VERSION}"
docker pull "$image"
docker image inspect "$image" > "$RESULT_FILE.image.json"
python3 - "$RESULT_FILE.image.json" "$RESULT_FILE" <<'PY'
import json,os,re,sys
image=json.load(open(sys.argv[1]))
matches=[x for x in image[0]['RepoDigests'] if x.startswith(os.environ['IMAGE_REPOSITORY']+'@sha256:')]
if len(matches)!=1: raise SystemExit('Expected one observed registry digest')
uri=matches[0]; digest=uri.split('@')[1]
if not re.fullmatch(r'sha256:[a-f0-9]{64}',digest): raise SystemExit('Invalid registry digest')
with open(sys.argv[2],'w') as out: json.dump({'artifact_uri':uri,'artifact_digest':digest,'build_version':os.environ['BUILD_VERSION']},out)
PY
rm -f -- "$RESULT_FILE.image.json"
