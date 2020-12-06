---
title: Entitled builds on OpenShift 4
linktitle: Entitled
weight: 5200
description: TBD
tags:
  - entitlement
---
# Entitled builds on OpenShift 4

**Resources**

 * [NVIDIA GPU Operator with OpenShift 4.3 on Red Hat OpenStack Platform 13
](https://egallen.com/gpu-operator-openshift-43-openstack-13/)
 * Official documentation: [Using Red Hat subscriptions in builds](https://docs.openshift.com/container-platform/4.4/builds/running-entitled-builds.html)

<!-- RedHat Internal: https://docs.google.com/document/d/1udIkiF_-R6LUEzIFCnoafu4dFpQnz04zFePFBu7RwTM/edit# -->
<!-- RedHat Internal: https://docs.google.com/document/d/1TlE4jGgYkID4wENAZ4LyZ3cKT8bGw2RWrpgbD6eEItI/edit# -->
<!-- https://issues.redhat.com/browse/DEVEXP-470 -->


**Options to rollout RHEL entitlement for container builds:**

 * Cluster-wide: via MachineConfig to the whole cluster and ALL running PODS
 * Per-Build: via Secrets / Configmaps per Container Build

## Cluster-wide entitlement

!!! warning
    All running POD's get access to the entitlement!

Create a machine config to rollout

 * /etc/rhsm/rhsm.conf
 * /etc/pki/entitlement/

Described in Blog article: [NVIDIA GPU Operator with OpenShift 4.3 on Red Hat OpenStack Platform 13
](https://egallen.com/gpu-operator-openshift-43-openstack-13/)

The files are mounted to ALL POD's/Containers: checkout crio's default mounts files:

```bash
[root@compute-0 ~]# cat /usr/share/containers/mounts.conf
/usr/share/rhel/secrets:/run/secrets
[root@compute-0 ~]# ls -la /usr/share/rhel/secrets
total 0
drwxr-xr-x. 2 root root 64 Jan  1  1970 .
drwxr-xr-x. 3 root root 21 Jan  1  1970 ..
lrwxrwxrwx. 3 root root 20 Apr 26 08:32 etc-pki-entitlement -> /etc/pki/entitlement
lrwxrwxrwx. 3 root root 28 Apr 26 08:32 redhat.repo -> /etc/yum.repos.d/redhat.repo
lrwxrwxrwx. 3 root root  9 Apr 26 08:32 rhsm -> /etc/rhsm
```
Documentation: [default_mounts_file](https://github.com/cri-o/cri-o/blob/master/docs/crio.conf.5.md#crioruntime-table)


## Per-Build entitlement

Example based von my [own-apache-container](https://github.com/openshift-examples/own-apache-container) example.

Just-for-information: Here the diff of changes I made in the Dockerfile to get it running on OpenShift 4: [Fixed Dockerfile.rhel - OpenShift 4 ready](https://github.com/openshift-examples/own-apache-container/commit/bfca5e6d4b2700f30ca91e1af53bbd76902c3334#diff-71a884046d6eedf388a5dc754169bb9c)

### Store entitlement in a secret

The entitlement contains the information which repos are available for the entitlement. List of available repos:
`rct cat-cert /etc/pki/entitlement/xxxxxx.pem`

```bash
oc create secret generic etc-pki-entitlement \
    --from-file /etc/pki/entitlement/xxxxxx.pem \
    --from-file /etc/pki/entitlement/xxxxxx-key.pem
```

### Create image streams

Not all images are easily accessible, in many cases you need access to registry.redhat.io.
You can provide the access to registry.redhat.io in the namespace or use the available access in the openshift namespace.

**Used in my dockerfile of my own-apache-container:**
```bash
oc import-image rhel7:7.6 \
  --from=registry.access.redhat.com/rhel7/rhel:7.6  \
  --namespace openshift \
  --confirm
```

### Build config

```bash hl_lines="26 27 28 29 30 33 34"
# Create imagestream own-apache-container-rhel7
oc create is own-apache-container-rhel7

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  annotations:
    openshift.io/generated-by: OpenShiftNewBuild
  creationTimestamp: null
  labels:
    build: own-apache-container-rhel7
  name: own-apache-container-rhel7
spec:
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: own-apache-container-rhel7:latest
  postCommit: {}
  resources: {}
  source:
    git:
      uri: https://github.com/openshift-examples/own-apache-container.git
    type: Git
    # IMPORTANT: mount the rhel entitlement
    secrets:
    - secret:
        name: etc-pki-entitlement
      destinationDir: etc-pki-entitlement
  strategy:
    dockerStrategy:
      # IMPORTANT: to select the rhel dockerfile
      dockerfilePath: Dockerfile.rhel
      from:
        kind: ImageStreamTag
        name: rhel7:7.6
        namespace: openshift
    type: Docker
  triggers:
  - type: ConfigChange
  - imageChange: {}
    type: ImageChange
status:
  lastVersion: 0
EOF

```

## Playground

### How to run a root rhel container with entitlement

```bash

# Create image stream (at openshift namespace)
oc import-image rhel7:7.6 \
  --from=registry.access.redhat.com/rhel7/rhel:7.6  \
  --namespace openshift \
  --confirm

# Create entitlement secret
oc create secret generic etc-pki-entitlement \
    --from-file /etc/pki/entitlement/3331047254240145326.pem \
    --from-file /etc/pki/entitlement/3331047254240145326-key.pem

# Service account
oc create sa anyuid

# Allow service anyuid to use SCC anyuid
oc create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scc-anyuid
rules:
- apiGroups:
  - security.openshift.io
  resourceNames:
  - anyuid
  resources:
  - securitycontextconstraints
  verbs:
  - use
EOF

oc create -f - <<EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sa-to-scc-anyuid
subjects:
  - kind: ServiceAccount
    name: anyuid
roleRef:
  kind: Role
  name: scc-anyuid
  apiGroup: rbac.authorization.k8s.io
EOF

```
#### Create secret with entitlement

The entitlement contains the information which repos are available for the entitlement. List of available repos:
`rct cat-cert /etc/pki/entitlement/3551555797900109932.pem`

```bash
oc create secret generic etc-pki-entitlement \
    --from-file /etc/pki/entitlement/3551555797900109932.pem \
    --from-file /etc/pki/entitlement/3551555797900109932-key.pem
```

#### Deploy rhel7

```bash

oc create deploymentconfig rhel7 \
  --image=rhel7:7.6 -- sleep infinity

oc patch dc/rhel7 \
    --type='json' \
    --patch='[
        {"op": "replace", "path": "/spec/template/spec/serviceAccount", "value": "anyuid"},
        {"op": "replace", "path": "/spec/template/spec/serviceAccountName", "value": "anyuid"}
    ]'

oc set volumes dc/rhel7 --add \
  --name=etc-pki-entitlement \
  --mount-path /etc/pki/entitlement \
  --secret-name=etc-pki-entitlement
```

#### Play with rhel7

```bash
$ oc rsh dc/rhel
sh-4.2# yum repolist
Loaded plugins: ovl, product-id, search-disabled-repos, subscription-manager
Repo rhel-7-server-rpms forced skip_if_unavailable=True due to: %(ca_cert_dir)sredhat-uep.pem
https://cdn.redhat.com/content/dist/rhel/server/7/7Server/x86_64/os/repodata/repomd.xml: [Errno 14] curl#77 - "Problem with the SSL CA cert (path? access rights?)"
Trying other mirror.
repolist: 0
sh-4.2#
```

!!! info
    **Problem:**
    Delete the `rm /etc/rhsm-host` first, rhel 7 can not handle an `/etc/rhsm-host/` without an `rhsm.conf`.
    Deleting of `/etc/rhsm-host` force the package managment to use `/etc/rhsm` provided by the container image together with entitlement mount.

```bash
sh-4.2# rm /etc/rhsm-host`
sh-4.2# yum repolist
Loaded plugins: ovl, product-id, search-disabled-repos, subscription-manager
rhel-7-server-rpms
(1/3): rhel-7-server-rpms/7Server/x86_64/group
(2/3): rhel-7-server-rpms/7Server/x86_64/updateinfo
(3/3): rhel-7-server-rpms/7Server/x86_64/primary_db
repo id                                                                                                           repo name                                                                                                                 status
rhel-7-server-rpms/7Server/x86_64                                                                                 Red Hat Enterprise Linux 7 Server (RPMs)                                                                                  28807
repolist: 28807
sh-4.2#
```
