---
title: OperatorHub
linktitle: OperatorHub
weight: 12300
description: TBD
---
# Own Operator in OperatorHub

## Build helm char

```bash
$ helm package helm-charts/chaos-professor/
Successfully packaged chart and saved it to: /Users/rbohne/q/openshift-examples/chaos-professor-operator/chaos-professor-0.1.2.tgz
```





opm index add opm index add --from-index=quay.io/openshift-examples/chaos-professor-operator-index:latest   --build-tool docker   --bundles quay.io/openshift-examples/chaos-professor-operator-bundle:v0.1.2   --tag  quay.io/openshift-examples/chaos-professor-operator-index:latest