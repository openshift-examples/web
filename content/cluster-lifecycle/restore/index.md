---
title: Restore
linktitle: Restore
description: Some information about restore
tags:
  - restore
  - kubeconfig
---

# Some information about restore

## Restore kubeconfig

```bash
cat .openshift_install_state.json \
    | jq '.["*kubeconfig.AdminClient"].File.Data' -r \
    | base64 -d > kubeconfig
```