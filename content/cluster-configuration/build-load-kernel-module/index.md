---
title: Build and load Kernel Model
linktitle: Kernel Module
description: An example how to build and load a kernel module.
tags:
  - kenrel
---

# Build and load Kernel Model

!!! note
    We need an entitlement to install kernel sources.

## Service account & privileges

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}service-account-and-rbac.yaml.yaml
    ```

=== "build-load-kernel-module.daemonset.yaml"

    ```yaml
    --8<-- "content/cluster-configuration/build-load-kernel-module/service-account-and-rbac.yaml"
    ```

## Entitlement

```bash
oc create secret generic etc-pki-entitlement \
  --from-file=entitlement.pem=./export/entitlement_certificates/xxx.pem
  --from-file entitlement-key.pem=./export/entitlement_certificates/xxx.pem
```

## DaemonSet / Deployment (Build & Run/Load)


=== "build-load-kernel-module.daemonset.yaml"

    ```yaml
    --8<-- "content/cluster-configuration/build-load-kernel-module/daemonset.yaml"
    ```

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}daemonset.yaml
    ```
