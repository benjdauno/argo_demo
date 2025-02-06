#!/bin/bash
set -euo pipefail

# Define the list of clusters.
clusters=(
  "control-plane"
  "dev"
  "staging"
  "prod-us"
)

# Define directories for kubeconfig files.
CONFIG_DIR="./kubeconfigs"
MAIN_KUBECONFIG="${CONFIG_DIR}/main-kubeconfig"

# Create directories if they do not exist.
mkdir -p "${CONFIG_DIR}"

# Helm chart repo for ArgoCD
ARGOCD_NAMESPACE="argocd"

echo "Starting creation of clusters..."
for cluster in "${clusters[@]}"; do
  if kind get clusters | grep -q "^${cluster}$"; then
    echo "Cluster ${cluster} already exists. Skipping creation."
    continue
  fi

  echo "Creating kind cluster: ${cluster}"
  kind create cluster --name "${cluster}" --kubeconfig "${CONFIG_DIR}/${cluster}-kubeconfig"
  

  echo "Cluster ${cluster} created and kubeconfig saved to ${CONFIG_DIR}/${cluster}-kubeconfig."
done

echo "All clusters have been created. The kubeconfig files are available in the '${CONFIG_DIR}' directory."

echo "Merging kubeconfig files into main kubeconfig..."
KUBECONFIGS=()
for cluster in "${clusters[@]}"; do
  KUBECONFIG_FILE="${CONFIG_DIR}/${cluster}-kubeconfig"
  if [[ -f "${KUBECONFIG_FILE}" ]]; then
    KUBECONFIGS+=("${KUBECONFIG_FILE}")
  else
    echo "Warning: Kubeconfig file ${KUBECONFIG_FILE} not found. Skipping."
  fi
done


if [[ ${#KUBECONFIGS[@]} -eq 0 ]]; then
  echo "Error: No kubeconfig files found for merging."
  exit 1
fi

export KUBECONFIG=$(IFS=:; echo "${KUBECONFIGS[*]}")
kubectl config view --merge --flatten > "${MAIN_KUBECONFIG}"
export KUBECONFIG="${MAIN_KUBECONFIG}"


echo "Main kubeconfig created at ${MAIN_KUBECONFIG}"

# Install ArgoCD on the control-plane cluster
echo "Installing Argo CD on control-plane cluster..."
export KUBECONFIG="${MAIN_KUBECONFIG}"
kubectl config use-context kind-control-plane
kubectl create namespace ${ARGOCD_NAMESPACE} || true
helm upgrade -i argocd argo/argo-cd -n ${ARGOCD_NAMESPACE} || true

echo "ArgoCD installation complete on the control-plane cluster."

# Generate cluster secrets for ArgoCD
echo "Generating Argo CD cluster secrets..."
for cluster in "${clusters[@]}"; do

  KUBECONFIG_FILE="${CONFIG_DIR}/${cluster}-kubeconfig"
  CLUSTER_NAME="${cluster}"

  # Get the Docker container ID for the cluster.
  container_id=$(docker ps -qf "name=${cluster}-control-plane")
  
  if [[ -z "${container_id}" ]]; then
    echo "Error: No such object: ${cluster}-control-plane"
    exit 1
  fi

  # Get the Docker container IP address for the cluster.
  server=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${container_id}")

  # Extract CA, cert, and key data using yq.
  ca_data=$(yq e '.clusters[0].cluster."certificate-authority-data"' "${KUBECONFIG_FILE}")
  cert_data=$(yq e '.users[0].user."client-certificate-data"' "${KUBECONFIG_FILE}")
  key_data=$(yq e '.users[0].user."client-key-data"' "${KUBECONFIG_FILE}")

  if [[ -z "${server}" || -z "${ca_data}" ]]; then
    echo "Error: Unable to extract necessary fields from ${KUBECONFIG_FILE}"
    exit 1
  fi

  # Generate the secret YAML.
  mkdir -p cluster-secrets
  secret_file="cluster-secrets/${CLUSTER_NAME}-cluster-secret.yaml"
  cat <<EOF > "${secret_file}"
apiVersion: v1
kind: Secret
metadata:
  name: cluster-${CLUSTER_NAME}
  namespace: ${ARGOCD_NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: cluster
stringData:
  name: ${CLUSTER_NAME}
  server: https://${server}:6443
  config: |
    {
    "tlsClientConfig": {
      "caData": "${ca_data}",
      "certData": "${cert_data}",
      "keyData": "${key_data}"
      }
    }
EOF

  echo "Applying ArgoCD cluster secret for ${CLUSTER_NAME}..."
  kubectl config use-context kind-control-plane
  kubectl apply -f "${secret_file}"

done

echo "All clusters registered with ArgoCD."
