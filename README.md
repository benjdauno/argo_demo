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

You can customize how many clusters are created with this script.

### Important Note on security

For the local setup, we commit cluster secrets to git, which is unsafe for production use. However, when using this setup with EKS and OIDC-based assume-role features, no sensitive information is committed to git. This ensures a secure and scalable deployment in a production environment.

The credentials that are committed to git here are throwaway keys that are only useful for the local development environment

## Usage

1. Fork the repository 
2. Clone the repository and navigate to the project directory.
3. Run the [`create_clusters.sh`](create_clusters.sh) script to set up the clusters and configure Argo CD:

    ```sh
    ./create_clusters.sh
    ```

3. Verify that the clusters are created and Argo CD is installed on the control plane cluster.

    ```
    kind get clusters
    export KUBECONFIG=kubeconfigs/main-kubeconfig
    kubectl get ns
    ```
4. Get a Github PAT with at least read access to your repo and put it in the repo-secret-template.yaml file before applying it to the cluster.

5. Port-forward yourself to the Argo CD UI and log in with the admin credentials.
User: admin  
Password:
    ```
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

6. Apply the manifests in applications and applicationsets.

## What's here?

There should be no applications generated from the clusters yet, except for the cluster secrets applications. In order to start generating applications, add labels to the cluster secrets, commit, push, and sync.

## What's not here?
This repo doesn't include an "App of ApplicationSets" that would be an umbrella syncing multiple applicationsets at a time. It could, I just didn't do that here to allow me to make quicker changes to applications.

### ApplicationSet Examples

The three ApplicationSets are three variations on a proposed structure for deploying an app to many clusters.

- cert-manager is the most straightforward, requiring only a label match to work and pull in an external helm chart.

- The otel collector demonstrates adding multiple values files to configure the applications, some of which may not be present.

- Finally, the dummy app is a demonstration of pulling in a chart that we're made in house. It's actually just the default scaffolding we get when running the helm create command.

## Experiment!

Add apps, change the structure, see what happens when you update labels, etc. The point is that all of this runs locally and can be iterated upon much faster than anything else we have at our disposal.

## Cleanup

To destroy the setup, run the [`delete_clusters.sh`](delete_clusters.sh) script. Check that clusters are in fact destroyed with 
```
kind get clusters
kind delete cluster --name <remaining-cluster> # delete any remaining clusters
```
