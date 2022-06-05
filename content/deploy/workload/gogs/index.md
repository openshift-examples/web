---
title: Gogs
linktitle: Gogs
description: A painless self-hosted Git service. <https://gogs.io>
tags:
  - demo
  - deployment
---

# Gogs

```
oc new-project gogs
oc create serviceaccount anyuid
oc adm policy add-scc-to-user -z anyuid anyuid
oc apply -f {{ page.canonical_url }}/deployment.yaml
```

Open the Gogs URL and configure gogs.


## Air-gapped information

```
oc image mirror \
  -a ${LOCAL_SECRET_JSON} \
  ghcr.io/gogs/gogs:latest \
  ${LOCAL_REGISTRY}/gogs/gogs:latest
```

And adjust the `deployment.yaml`

