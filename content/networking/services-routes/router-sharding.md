---
title: Router sharding example
linktitle: Router sharding
description: TBD
alias:
- "/basics/router-sharding/"
---
# Router sharding example

## Create a new router shared

Take all routes with label `type=sharded`

```bash
oc create -f - <<EOF
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  name: sharded
  namespace: openshift-ingress-operator
spec:
  domain: external.demo.openshift.pub
  endpointPublishingStrategy:
    type: NodePortService
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/worker: ""
  routeSelector:
    matchLabels:
      type: sharded
status: {}
EOF
```

## Adjust default router to skip `type: sharded`

```bash
oc patch \
  -n openshift-ingress-operator \
  IngressController/default \
  --type='merge' \
  -p '{"spec":{"routeSelector":{"matchExpressions":[{"key":"type","operator":"NotIn","values":["sharded"]}]}}}'
```

## Dummy routes

```bash
oc new-project demo
oc create service clusterip dummy --tcp=8080:8080
oc expose svc/dummy -l type=sharded --name dummy-shared
oc expose svc/dummy --name dummy-default
```

Check routes

```bash
$ oc describe route -n demo dummy-default
Name:			dummy-default
Namespace:		demo
Created:		2 minutes ago
Labels:			app=dummy
Annotations:		openshift.io/host.generated=true
Requested Host:		dummy-default-demo.apps.demo.openshift.pub
			  exposed on router default (host apps.demo.openshift.pub) 2 minutes ago
Path:			<none>
TLS Termination:	<none>
Insecure Policy:	<none>
Endpoint Port:		8080-8080

Service:	dummy
Weight:		100 (100%)
Endpoints:	<none>

$ oc describe route -n demo dummy-shared
Name:			dummy-shared
Namespace:		demo
Created:		3 minutes ago
Labels:			type=sharded
Annotations:		openshift.io/host.generated=true
Requested Host:		dummy-shared-demo.apps.demo.openshift.pub
			  exposed on router sharded (host external.demo.openshift.pub) 2 minutes ago
Path:			<none>
TLS Termination:	<none>
Insecure Policy:	<none>
Endpoint Port:		8080-8080

Service:	dummy
Weight:		100 (100%)
Endpoints:	<none>



$ oc rsh -n openshift-ingress deployment/router-sharded cat os_http_be.map
^dummy-shared-demo\.apps\.demo\.openshift\.pub(:[0-9]+)?(/.*)?$ be_http:demo:dummy-shared

$ oc rsh -n openshift-ingress deployment/router-default cat os_http_be.map
^dummy-default-demo\.apps\.demo\.openshift\.pub(:[0-9]+)?(/.*)?$ be_http:demo:dummy-default


```

One downside: all routes auto generated with default domain:

```bash
$ oc get ingresses.config.openshift.io/cluster -o jsonpath="{.spec.domain}"
apps.demo.openshift.pub
```
