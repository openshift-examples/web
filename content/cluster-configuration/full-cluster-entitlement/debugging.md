---
title: Entitlement debugging
linktitle: Entitlement debugging
description: Entitlement debugging
tags:
  - entitlement

---
# Entitlement debugging


```
curl -I -XGET  \
  --cacert /etc/rhsm/ca/redhat-uep.pem \
  --key /etc/pki/entitlement-host/3034856157177793453-key.pem \
  --cert /etc/pki/entitlement-host/3034856157177793453.pem \
  https:/cdn.redhat.com/content/dist/rhel8/8/x86_64/baseos/os/repodata/repomd.xml
```