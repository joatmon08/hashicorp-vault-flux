# Using HashiCorp Vault with Flux to Inject Secrets

This is a repository that demonstrates how to use HashiCorp Vault
with Flux.

Ideally, you should use a [file-based](https://www.vaultproject.io/docs/platform/k8s) approach to injecting
secrets into your applications and omit Kubernetes secrets.

However, some tools, like Flux, need Kubernetes secrets for setup.

As a solution, you can use the [Secrets Store CSI driver's Sync as Kubernetes Secret](https://secrets-store-csi-driver.sigs.k8s.io/topics/sync-as-kubernetes-secret.html)
capability with the [Vault CSI provider](https://www.vaultproject.io/docs/platform/k8s/csi).

This means that the Vault CSI provider will retrieve the secret from Vault and synchronize it to a Kubernetes
secret.

> __NOTE:__ This configuration will not work for you out of the box. You need
  to update the `GitRepository` sources to point to your own GitHub and GitLab
  repositories!

## Prerequisites

- Kubernetes cluster 1.24+ (Docker Desktop)
- Terraform v1.1+
- Vault v1.10+
- Flux v0.30+
- GitHub Personal Access Token
- GitLab Personal Access Token

## Usage

Set up secrets in your terminal.

```shell
export GITHUB_TOKEN=<PAT from GitHub>
export GITLAB_TOKEN=<PAT from GitLab>
```

Install ingress to the cluster. This will make it easier
for you to access Vault from outside of the cluster.

```shell
make ingress
```

Bootstrap Flux and apply the configuration. This will
deploy Vault and all of the necessary components.

```shell
make flux-bootstrap
```

### Set up Vault and GitLab

Initialize Vault. Copy the value from `unseal_keys_hex` in
`unseal.json` to pass to the input command.

```shell
make vault-init
```

Set up Vault credentials in shell.

```shell
export VAULT_TOKEN=$(cat unseal.json | jq -r '.root_token')
export VAULT_ADDR=http://localhost
```

Install secrets engines, including the database secrets engine.

```shell
make vault-configure
```

Set up secret bootstrap to inject flux deploy token.

```shell
make flux-token
```

### Set up the Application

Clone your GitLab project's repository, called `hashicups`.

```shell
cd ~
git clone git@gitlab.com:<your gitlab username>/hashicups.git
```

Copy the `application/` folder in this working directory
to the `hashicups` GitLab repository.

```shell
cp application/ ~/<your gitlab username>/hashicups/
```

Push the changes to GitLab.

```shell
git add .
git commit -m "Initial commit"
git push
```

Install applications.

```shell
make applications
```

## Clean up

```shell
make clean
```