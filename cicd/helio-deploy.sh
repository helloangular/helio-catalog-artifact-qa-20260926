#!/usr/bin/env bash
set -euo pipefail
: "${RESULT_FILE:?}" "${ARTIFACT_URI:?}" "${ARTIFACT_DIGEST:?}" "${TARGET_ENVIRONMENT:?}" "${OPERATION_ID:?}"
[[ "$TARGET_ENVIRONMENT" =~ ^[a-z0-9][a-z0-9._-]{0,62}$ ]]
[[ "$ARTIFACT_DIGEST" =~ ^sha256:[a-f0-9]{64}$ ]]
[[ "$ARTIFACT_URI" == "ghcr.io/${GITHUB_REPOSITORY,,}@${ARTIFACT_DIGEST}" ]]
DOCKER_CONFIG="$(mktemp -d)"; export DOCKER_CONFIG
trap 'rm -rf -- "$DOCKER_CONFIG"' EXIT
printf '%s' "$REGISTRY_TOKEN" | docker login ghcr.io -u "$REGISTRY_USER" --password-stdin
export CONTAINER_NAME="helio-${GITHUB_REPOSITORY//\//-}-${TARGET_ENVIRONMENT}"
# This supplied adapter qualifies a local Docker target on a dedicated runner.
# Remote Ansible targets require registry auth at those hosts and a reviewed
# playbook with the same independent inspection and all-host success contract.
playbook="${HELIO_ANSIBLE_PLAYBOOK:-/opt/helio-catalog-profile-qa/venv/bin/ansible-playbook}"
"$playbook" -i localhost, -c local cicd/helio-deploy-docker.yml
test -s "$RESULT_FILE"
