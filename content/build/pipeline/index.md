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

Get basis tasks from [buildah.yaml](https://github.com/tektoncd/catalog/blob/main/task/buildah/0.2/buildah.yaml) and adjust it.

Create secret
```bash
oc create secret generic build-args \
  --from-literal=USERNAME=web-auth-user \
  --from-literal=PASSWORD=IeNae1eigheBiz8ne

```
Create BuildConfig
```yaml
oc apply -f - <<EOF
--8<-- "content/build/pipeline/files/buildah.yaml"
EOF
```
