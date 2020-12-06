---
title: Air-gapped Operator LifeCycle Manager / OperatorHub => 4.6
weight: 12010
description: TBD
linktitle: Air-gapped OLM >= 4.6
tags:
  - air-gapped
  - disconnected
  - restricted-network
---
# Air-gapped Operator LifeCycle Manager / OperatorHub => 4.6
## Official resources


 * [Using Operator Lifecycle Manager on restricted networks](https://docs.openshift.com/container-platform/4.6/operators/admin/olm-restricted-networks.html)


## Dell CSI Operator example (Spoiler: Dell CSI Operator won't work)

### Disable all default catalog sources

```bash
oc patch OperatorHub cluster --type json \
    -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

### Sync ond Operator

#### Necessary environment variables:

```bash
export OCP_RELEASE=$(oc version -o json  --client | jq -r '.releaseClientVersion')
export LOCAL_REGISTRY='host.compute.local:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='/root/hetzner-ocp4/pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64
```

#### Install tools

##### OPM
```bash
oc image extract registry.redhat.io/openshift4/ose-operator-registry:v${OCP_RELEASE%\.*} \
    -a ${LOCAL_SECRET_JSON} \
    --path /usr/bin/opm:/usr/local/bin/ \
    --confirm
chmod +x /usr/local/bin/opm
```
##### grpcurl

```bash
curl -# -L -o /tmp/grpcurl.tar.gz https://github.com/fullstorydev/grpcurl/releases/download/v1.7.0/grpcurl_1.7.0_linux_x86_64.tar.gz \
 && tar xzvf /tmp/grpcurl.tar.gz -C /usr/local/bin/ grpcurl \
 && chmod +x /usr/local/bin/grpcurl \
 && rm /tmp/grpcurl.tar.gz
```

#### Find out certified operator

```bash
podman run -p50051:50051 --authfile ${LOCAL_SECRET_JSON} -it \
  registry.redhat.io/redhat/certified-operator-index:v${OCP_RELEASE%\.*}
```
Second terminal:

```bash
$ grpcurl -plaintext localhost:50051 api.Registry/ListPackages | grep dell
  "name": "dell-csi-operator-certified"
```

#### Install registry cred.

```bash
mkdir -p /run/user/$(id -u)/containers
cp -v ${LOCAL_SECRET_JSON} /run/user/$(id -u)/containers/auth.json
```

#### Build own certified-operator-index

OPM is sometimes difficult:
 * min Podman version 2 ([Bug 1894167](https://bugzilla.redhat.com/show_bug.cgi?id=1894167) - OPM fails to create a pruned index image)
 * [Work-a-round use podman directly](https://bugzilla.redhat.com/show_bug.cgi?id=1894167#c1)


```bash
opm index prune \
    -f registry.redhat.io/redhat/certified-operator-index:v${OCP_RELEASE%\.*} \
    -p dell-csi-operator-certified \
    -t ${LOCAL_REGISTRY}/redhat/certified-operator-index:v${OCP_RELEASE%\.*}

podman push ${LOCAL_REGISTRY}/redhat/certified-operator-index:v${OCP_RELEASE%\.*}

```

#### Apply catalog sources
```yaml
oc create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: dell-csi-operator
  namespace: openshift-marketplace
spec:
  displayName: dell-csi-operator
  image: ${LOCAL_REGISTRY}/redhat/certified-operator-index:v${OCP_RELEASE%\.*}
  publisher: dell-csi-operator
  sourceType: grpc
EOF
```

#### Mirror operator images

* [Bug 1890951](https://bugzilla.redhat.com/show_bug.cgi?id=1890951) - Mirror of multiarch images together with cluster logging case problems. It doesn't sync the "overall" sha it syncs only the sub arch sha.

```
oc adm catalog mirror \
    ${LOCAL_REGISTRY}/redhat/certified-operator-index:v${OCP_RELEASE%\.*} \
    ${LOCAL_REGISTRY} \
    -a ${LOCAL_SECRET_JSON} \
    --to-manifests=certified-operator-index/

oc apply -f certified-operator-index/imageContentSourcePolicy.yaml
```

#### Watch until imageContentSourcePolicy is rolled out

```bash
watch  oc get mcp,nodes
```

##### Install Dell CSI Operator via OperatorHub/OLM

and you got an error:

```bash
$ oc get pods -l name=dell-csi-operator -n openshift-operators
NAME                                 READY   STATUS                  RESTARTS   AGE
dell-csi-operator-74b94b7467-9mhdr   0/1     Init:ImagePullBackOff   0          26m
```

Because the Dell CSI Operator use images names and not full image urls:

```bash
$ oc get pods -l name=dell-csi-operator -n openshift-operators -o jsonpath="{.items[0].spec.initContainers[0].image}"
busybox@sha256:a9286defaba7b3a519d585ba0e37d0b2cbee74ebfe590960b0b1d6a5e97d1e1d
$ oc get pods -l name=dell-csi-operator -n openshift-operators -o jsonpath="{.items[0].spec.containers[0].image}"
dellemc/dell-csi-operator@sha256:113435c9d0d805a2d7f4e6b5bdd6d21a3e489cb0278a9e81b2bc142c0fd5eb0f

```

