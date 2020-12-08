---
title: Route encryption
linktitle: Route encryption
weight: 4410
description: TBD
---
# Route encryption

## Edge

```yaml {linenos=table,hl_lines=[12 13 14]}
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: test2
spec:
  to:
    kind: Service
    name: test
    weight: 100
  port:
    targetPort: 80
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```
