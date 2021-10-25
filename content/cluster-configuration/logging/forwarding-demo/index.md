---
title: Log Forwarding demo
linktitle: Log Forwarding API
weight: 18100
description: TBD
---
# Log Forwarding demo

## Start fluentd to file logging

#### Create new project

=== "OC"

    ```
    oc new-project fluentd
    ```

#### Deploy fluentd

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}deploy-fluentd.yaml
    ```

=== "buildah-with-secret.yaml"

    ```yaml
    --8<-- "content/cluster-configuration/logging/forwarding-demo/deploy-fluentd.yaml"
    ```

### Test fluentd

Login into the pod:

```bash
$ oc rsh deployment/fluentd bash
```

Run command inside the pod:
```bash
$ echo '{"message":"fooobar"}' | fluent-cat debug.log --host fluentd.fluentd.svc.cluster.local  --port 24224
$ grep fooobar /fluentd/log/data.log
2020-10-28T10:42:24+00:00	debug.log	{"message":"fooobar"}
```

## Deploy Cluster Logging

 * Deploy OpenShift Logging Operator
 * Deploy Elastic Search Operator from Red Hat.

```yaml
oc create -f - <<EOF
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  collection:
    logs:
      fluentd: {}
      type: fluentd
EOF
```


## Deploy Log forwarding api


```yaml
oc create -f - <<EOF
apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  outputs:
   - name: fluentd-server-insecure
     type: fluentdForward
     url: 'tcp://fluentd.fluentd.svc.cluster.local:24224'
  pipelines:
   - name: fluentd-server-insecure-name
     inputRefs:
     - audit
     outputRefs:
     - fluentd-server-insecure
     parse: json
     labels:
       clusterId: "C1234"
EOF
```


## Viewing audit logs

Usefull tool: [cluster-debug-tools](https://github.com/openshift/cluster-debug-tools)

```
# Extract auditlog from PV
$ cat data.log | grep k8s-audit.log | cut -f3- > audit.log

$ kubectl dev_tool audit -f audit.log  | head
14:31:55 [ WATCH][1h29m7.534747s] [200] /api/v1/namespaces/openshift-console-user-settings/configmaps?watch=true&fieldSelector=metadata.name%3Duser-settings-kubeadmin                                                                                                                              [kube:admin]
14:52:32 [ WATCH][1h8m30.575234s] [200] /apis/console.openshift.io/v1/consolenotifications?watch=true&resourceVersion=79435                                                                                                                                                                         [kube:admin]
15:02:13 [ WATCH][58m50.081621s] [200]  /apis/console.openshift.io/v1/consolelinks?watch=true&resourceVersion=83292                                                                                                                                                                                 [kube:admin]
15:08:26 [ WATCH][52m36.517786s] [200]  /apis/apiregistration.k8s.io/v1/apiservices?watch=true&resourceVersion=85827                                                                                                                                                                                [kube:admin]
15:14:16 [ WATCH][46m47.349073s] [200]  /apis/console.openshift.io/v1/consolequickstarts?watch=true&resourceVersion=88167                                                                                                                                                                           [kube:admin]
15:24:42 [ WATCH][36m20.76974s] [200]   /apis/config.openshift.io/v1/clusterversions?watch=true&fieldSelector=metadata.name%3Dversion                                                                                                                                                               [kube:admin]
15:49:29 [ WATCH][9m51.001757s] [200]   /api/v1/namespaces/openshift-kube-scheduler-operator/endpoints?allowWatchBookmarks=true&resourceVersion=102447&timeout=9m51s&timeoutSeconds=591&watch=true                                                                                                  [system:serviceaccount:openshift-monitoring:prometheus-k8s]
15:49:30 [ WATCH][9m55.001174s] [200]   /apis/config.openshift.io/v1/ingresses?allowWatchBookmarks=true&resourceVersion=102455&timeout=9m55s&timeoutSeconds=595&watch=true                                                                                                                          [system:serviceaccount:openshift-apiserver-operator:openshift-apiserver-operator]
15:49:37 [ WATCH][9m57.000757s] [200]   /api/v1/namespaces/openshift-marketplace/pods?allowWatchBookmarks=true&resourceVersion=102513&timeout=9m57s&timeoutSeconds=597&watch=true                                                                                                                   [system:serviceaccount:openshift-monitoring:prometheus-k8s]
15:49:40 [ WATCH][9m50.001387s] [200]   /api/v1/namespaces?allowWatchBookmarks=true&resourceVersion=102501&timeoutSeconds=590&watch=true                                                                                                                                                            [system:serviceaccount:openshift-monitoring:prometheus-operator]

```


