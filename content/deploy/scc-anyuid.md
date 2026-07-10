---
title: Non-root/anyuid (SCC)
linktitle: Non-root/anyuid (SCC)
description: How to work with security context constaints (SCC) especilly non-root-v2 / anyuid
tags: ['scc','v4.21']
---
# How to work with non-root/Anyuid (SCC)

|Component|Version|
|---|---|
|OpenShift|v4.21.22|

Official documentation: [Managing security context constraints](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/authentication_and_authorization/managing-pod-security-policies)

## How SCC selection works

Based on: [SCC Prioritization - OpenShift Documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/authentication_and_authorization/managing-pod-security-policies#scc-prioritization_configuring-internal-oauth)

When a workload is created, only the **service account** is used to find SCCs — not the creating user. The admission controller:

1. **Retrieves** all SCCs the service account can `use` (via RBAC).
2. **Generates** default values for unset security context fields from the pod spec.
3. **Sorts** candidates: highest priority first, then most restrictive first, then by name.
4. **Validates** the pod against each SCC in order — the first match wins and is recorded in the `openshift.io/scc` annotation. If none match, the pod is rejected.

The result: pods get the **most restrictive SCC that still allows them to run**.

!!! tip
    You can pin a specific SCC to a workload by setting the `openshift.io/required-scc` annotation on the pod template. The SCC must exist and the service account must have `use` permission for it.

## Create project and service account

```shell
oc new-project anyuid-demo
oc create sa anyuid
```

## Allow service account to use scc anyuid

```shell
oc adm policy add-scc-to-user -n anyuid-demo -z anyuid anyuid
```

It create a rolebinding:

```shell
% oc get rolebinding system:openshift:scc:anyuid -o yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  creationTimestamp: "2026-07-10T09:00:56Z"
  name: system:openshift:scc:anyuid
  namespace: anyuid-demo
  resourceVersion: "439866"
  uid: 7179d278-4b80-4f6c-b709-1e15ada8e08e
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:openshift:scc:anyuid
subjects:
- kind: ServiceAccount
  name: anyuid
  namespace: anyuid-demo
```

## Deployment




### without-anyuid

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: without-anyuid
spec:
  replicas: 1
  selector:
    matchLabels:
      app: without-anyuid
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: without-anyuid
    spec:
      containers:
        - name: ubi
          image: registry.access.redhat.com/ubi9/ubi-micro:9.8-1782840931
          command:
            - /bin/sh
            - '-c'
            - |
              echo -n "id: "
              id;
              sleep infinity
```

```shell
% oc logs deployment/without-anyuid
id: uid=1000750000(1000750000) gid=0(root) groups=0(root),1000750000
```


### with-anyuid

!!! note
    Important is the and `serviceAccountName`!

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: with-anyuid
spec:
  replicas: 1
  selector:
    matchLabels:
      app: with-anyuid
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: with-anyuid
    spec:
      serviceAccountName: anyuid
      containers:
        - name: ubi
          image: registry.access.redhat.com/ubi9/ubi-micro:9.8-1782840931
          command:
            - /bin/sh
            - '-c'
            - |
              echo -n "id: "
              id;
              sleep infinity
```

```shell
% oc logs deployment/with-anyuid
id: uid=0(root) gid=0(root) groups=0(root)
```

## List of pods

```shell
% oc get pods -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,SCC:.metadata.annotations."openshift\.io/scc",REQ-SCC:.metadata.annotations."openshift\.io/required-scc"
NAMESPACE     NAME                              SCC             REQ-SCC
anyuid-demo   with-anyuid-7769dfb79-6kpd5       anyuid          <none>
anyuid-demo   without-anyuid-55b5b5fd9f-8j9vb   restricted-v2   <none>
```
