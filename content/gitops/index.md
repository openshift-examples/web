---
title: GitOps
linktitle: GitOps
description: All about GitOps
tags:
  - gitops
  - argocd
---

# GitOps

## ArgoCD comand line

```
argocd login --username admin \
  --password $(oc get secrets -n openshift-gitops openshift-gitops-cluster -o jsonpath="{.data.admin\.password}" | base64 -d) \
  --insecure \
  $(oc get route -n openshift-gitops openshift-gitops-server -o jsonpath="{.spec.host}")

```

## Sealed secrets

Installed via OLM: <https://github.com/openshift-examples/apps/tree/main/cluster-scope/components/sealed-secrets-operator>

Important, a rolebinding to get all admins access to sealedsecrets object:

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sealedsecrets-admin
  labels:
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
rules:
  - apiGroups:
      - "bitnami.com"
    resources:
      - SealedSecret
    verbs:
      - "*"
```

```bash
kubeseal  \
  --controller-name sealed-secret-controller-sealed-secrets \
  --controller-namespace sealed-secrets \
  --fetch-cert

kubeseal \
  --controller-name sealed-secret-controller-sealed-secrets \
  --controller-namespace sealed-secrets \
  --format yaml \
  < <(oc create secret generic test --from-literal=key1=supersecret --dry-run=client -o yaml)
```

## KSOP

<https://blog.oddbit.com/post/2021-03-09-getting-started-with-ksops/>

```
# Kustomize
curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.2.0/kustomize_v4.2.0_linux_amd64.tar.gz | tar xz
install -m 755
sudo install -m 755 kustomize /usr/local/bin/kustomize
rm kustomize

# SOPS
curl -L -o sops https://github.com/mozilla/sops/releases/download/v3.7.1/sops-v3.7.1.linux
sudo install -m 755 sops /usr/local/bin/sops
rm sops

# KSOPS Plugin
curl -L https://github.com/viaduct-ai/kustomize-sops/releases/download/v2.5.7/ksops_2.5.7_Linux_x86_64.tar.gz | tar xz ksops
mkdir  -p ~/.config/kustomize/plugin/viaduct.ai/v1/ksops/
install -m 755 ksops ~/.config/kustomize/plugin/viaduct.ai/v1/ksops/ksops
rm ksops
```


## Resources & Examples

 * <https://github.com/openshift-examples/apps>
 * <https://github.com/gnunn-gitops/standards> => Text-Beschreibung
 * <https://github.com/gnunn-gitops/cluster-config> => Example für Cluster Config (von Gerald)
 * <https://github.com/PixelJonas/cluster-gitops> => Example Cluster Config (von nem anderen dude)
 * <https://github.com/redhat-canada-gitops/catalog> => Repo mit kustomize base-folder für verschiedene Operator und/oder KOnfigurationenexi


 https://argoproj.github.io/argo-cd/faq/#why-is-my-app-out-of-sync-even-after-syncing

