---
title: Tekton / OpenShift Pipelines
linktitle: Pipelines
description: OpenShift Pipeline examples
tags:
  - tekton
  - pipeline
  - build
---

# Tekton / OpenShift Pipelines


## Container build (buildah) with secrets

Task documentation: <https://tekton.dev/docs/pipelines/tasks/>

#### Create secret

```bash
oc create secret generic build-args \
  --from-literal=USERNAME=web-auth-user \
  --from-literal=PASSWORD=IeNae1eigheBiz8ne
```

#### Apply buildah-with-secret task:

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}buildah-with-secret.yaml
    ```

=== "buildah-with-secret.yaml"

    ```yaml
    --8<-- "content/build/pipeline/buildah-with-secret.yaml"
    ```


#### Apply pipeline:

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}buildah-pipeline.yaml
    ```

=== "buildah-pipeline.yaml"

    ```yaml
    --8<-- "content/build/pipeline/buildah-pipeline.yaml"
    ```