#!/bin/bash
set -euo pipefail

# Define the same list of clusters.
clusters=(
  "control-plane"
  "dev"
#  "staging1"
#  "staging2"
#  "prod-us1"
#  "prod-us2"
#  "prod-eu"
)

CONFIG_DIR="./kubeconfigs"

echo "Starting deletion of clusters..."
for cluster in "${clusters[@]}"; do
  echo "Deleting kind cluster: ${cluster}"
  kind delete cluster --name "${cluster}"
done

# Optionally remove the directory with kubeconfig files.
if [[ -d "${CONFIG_DIR}" ]]; then
  rm -rf "${CONFIG_DIR}"
  echo "Removed the kubeconfig directory: ${CONFIG_DIR}"
fi

echo "All clusters have been deleted."
