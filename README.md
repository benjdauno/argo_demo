# Simulating Multiple Clusters with Argo CD Control Plane

This project demonstrates the setup of multiple Kubernetes clusters using `kind` (Kubernetes in Docker) with a control plane managed by Argo CD. The control plane cluster hosts Argo CD, which manages the application deployments across other clusters.

## Prerequisites

Before you begin, ensure you have the following tools installed:

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) - Kubernetes in Docker
- [helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- [yq](https://github.com/mikefarah/yq) - YAML processor

## Local Setup

The local setup involves creating multiple `kind` clusters and configuring Argo CD to manage these clusters. The [`create_clusters.sh`](create_clusters.sh) script automates this process by:

1. Creating the control plane and application clusters.
2. Extracting the kubeconfig files for each cluster.
3. Installing Argo CD on the control plane cluster.
4. Generating and applying cluster secrets for Argo CD to manage the application clusters.

### Important Note

For the local setup, the script commits secrets to git, which is unsafe for production use. However, when using this setup with EKS and OIDC-based assume-role features, no sensitive information is committed to git. This ensures a secure and scalable deployment in a production environment.

## Usage

1. Clone the repository and navigate to the project directory.
2. Run the [`create_clusters.sh`](create_clusters.sh) script to set up the clusters and configure Argo CD:

    ```sh
    ./create_clusters.sh
    ```

3. Verify that the clusters are created and Argo CD is installed on the control plane cluster.

4. Access the Argo CD UI to manage and monitor the application deployments across the clusters.

## Cleanup

To delete the clusters and clean up the environment, run the [delete_clusters.sh](delete_clusters.sh) script:

```sh
./delete_clusters.sh
```
