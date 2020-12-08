---
title: Cluster autoscaling
linktitle: Cluster autoscaling
description: All about autoscaling on cluster level
tags:
  - autoscaling
---

# Cluster autoscaling

Documentation: [Applying autoscaling to an OpenShift Container Platform cluster](https://docs.openshift.com/container-platform/latest/machine_management/applying-autoscaling.html)


## MachineAutoscaler resource definition

```yaml
oc apply -f - <<EOF
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "vmw-mbqt7-worker"
  namespace: "openshift-machine-api"
spec:
  minReplicas: 3
  maxReplicas: 6
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: vmw-mbqt7-worker
EOF
```

## ClusterAutoscaler resource definition

```yaml
oc apply -f - <<EOF
apiVersion: "autoscaling.openshift.io/v1"
kind: "ClusterAutoscaler"
metadata:
  name: "default"
spec:
  podPriorityThreshold: -10
  resourceLimits:
    maxNodesTotal: 10
    cores:
      min: 8
      max: 128
    memory:
      min: 4
      max: 256
  scaleDown:
    enabled: true
    delayAfterAdd: 10m
    delayAfterDelete: 5m
    delayAfterFailure: 30s
    unneededTime: 60s
EOF
```


## Start resources

```bash
oc new-project nginx
oc new-app nginx-example

$ oc get deploymentconfig
NAME            REVISION   DESIRED   CURRENT   TRIGGERED BY
nginx-example   0          1         0         config,image(nginx-example:latest)


$ oc patch dc/nginx-example \
    --type='json' \
    --patch='[
        {"op": "replace", "path": "/spec/template/spec/containers/0/resources", "value": {"limits":{"memory":"1Gi","cpu": 1},"requests":{"memory":"1Gi","cpu": 1}}}
    ]'

$ oc get nodes
NAME                     STATUS   ROLES    AGE   VERSION
vmw-mbqt7-master-0       Ready    master   25d   v1.19.0+9f84db3
vmw-mbqt7-master-1       Ready    master   25d   v1.19.0+9f84db3
vmw-mbqt7-master-2       Ready    master   25d   v1.19.0+9f84db3
vmw-mbqt7-worker-dsstf   Ready    worker   25d   v1.19.0+9f84db3
vmw-mbqt7-worker-plvzh   Ready    worker   25d   v1.19.0+9f84db3
vmw-mbqt7-worker-s8p6t   Ready    worker   25d   v1.19.0+9f84db3
$ oc get machines -n openshift-machine-api
NAME                     PHASE     TYPE   REGION   ZONE   AGE
vmw-mbqt7-master-0       Running                          25d
vmw-mbqt7-master-1       Running                          25d
vmw-mbqt7-master-2       Running                          25d
vmw-mbqt7-worker-dsstf   Running                          25d
vmw-mbqt7-worker-plvzh   Running                          25d
vmw-mbqt7-worker-s8p6t   Running                          25d

$ oc scale dc/nginx-example --replicas=100
deploymentconfig.apps.openshift.io/nginx-example scaled

# After a while:

$ oc get nodes
NAME                     STATUS   ROLES    AGE   VERSION
vmw-mbqt7-master-0       Ready    master   25d   v1.19.0+9f84db3
vmw-mbqt7-master-1       Ready    master   25d   v1.19.0+9f84db3
vmw-mbqt7-master-2       Ready    master   25d   v1.19.0+9f84db3
vmw-mbqt7-worker-dsstf   Ready    worker   25d   v1.19.0+9f84db3
vmw-mbqt7-worker-plvzh   Ready    worker   25d   v1.19.0+9f84db3
vmw-mbqt7-worker-s8p6t   Ready    worker   25d   v1.19.0+9f84db3
$ oc get machines
NAME                     PHASE          TYPE   REGION   ZONE   AGE
vmw-mbqt7-master-0       Running                               25d
vmw-mbqt7-master-1       Running                               25d
vmw-mbqt7-master-2       Running                               25d
vmw-mbqt7-worker-2sgmh   Provisioning                          21s
vmw-mbqt7-worker-dsstf   Running                               25d
vmw-mbqt7-worker-plvzh   Running                               25d
vmw-mbqt7-worker-s6cr2   Provisioning                          21s
vmw-mbqt7-worker-s8p6t   Running                               25d
vmw-mbqt7-worker-tmx82   Provisioning                          21s
$ oc get pods -n nginx | wc -l
     104

```