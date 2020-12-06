---
title: JFrog Artifactory Enterprise Operator
linktitle: JFrog Artifactory
weight: 8100
description: TBD
tags:
 - air-gapped
 - restriced-network
 - disconnected
---

# JFrog Artifactory Enterprise Operator

How to setup JFrog Artifactory Enterprise Operator on a disconnected cluster

Tested on OpenShift 4.5.14

Operator mirror follows the official documentation: [Using Operator Lifecycle Manager on restricted networks](https://docs.openshift.com/container-platform/4.5/operators/admin/olm-restricted-networks.html)

##  Export some environment variables

Some variables for better copy&paste experience of commands.

```bash
export OCP_RELEASE=$(oc version -o json  --client | jq -r '.releaseClientVersion')
export LOCAL_REGISTRY='host.compute.local:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='/root/hetzner-ocp4/pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64
export KUBECONFIG=/root/hetzner-ocp4/air-gapped/auth/kubeconfig
# export SERIAL=$(date +%s)
export SERIAL=1604840032
```
## Setup a PostgreSQL database

For demo purpose we only setup a singe instance PostgreSQL, for production usage you should setup a PostgreSQL cluster.

### Mirror images

```bash
oc image mirror \
  -a ${LOCAL_SECRET_JSON} \
  --filter-by-os='.*' \
  registry.redhat.io/rhel8/postgresql-12:latest  \
  ${LOCAL_REGISTRY}/rhel8/postgresql-12:latest
```

### Deploy PostgreSQL

```bash
oc import-image -n openshift postgresql:12-el8 --from=${LOCAL_REGISTRY}/rhel8/postgresql-12:latest --confirm

oc process -f https://raw.githubusercontent.com/openshift/library/master/official/postgresql/templates/postgresql-persistent.json \
  -p POSTGRESQL_VERSION=12-el8 \
  -p POSTGRESQL_USER=jfrog \
  -p POSTGRESQL_PASSWORD=jfrog \
  -p POSTGRESQL_DATABASE=jfrog  | oc apply -f -
```

## Build catalog of certified-operators

```bash
oc adm catalog build \
  --appregistry-org certified-operators \
  --from=registry.redhat.io/openshift4/ose-operator-registry:v4.5 \
  --to=${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL} \
  -a ${LOCAL_SECRET_JSON} 2>&1 | tee certified-operators.build.${SERIAL}.log
```

### Apply catalog source

```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-certified-operators-${SERIAL}
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: ${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL}
  displayName: My Red Hat Catalog ${SERIAL}
  publisher: grpc
EOF
```


### Check after a while if the jFrog Artifactory Operator is available

```bash
$ oc get  packagemanifests -n openshift-marketplace openshiftartifactoryha-operator
NAME                              CATALOG                         AGE
openshiftartifactoryha-operator   My Red Hat Catalog 1604840032   2m54s
```


## Mirroring images

To save time, bandwidth and storage I mirrored only the necessary images.

### Find out necessary images

```bash
$ podman run --authfile ${LOCAL_SECRET_JSON} -ti --rm --entrypoint bash  ${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL}
sh-4 $ echo "select image from related_image \
      where operatorbundle_name like 'artifactory-ha-operator%';"       | sqlite3 -line /bundles.db | grep -v '^$' | sort -u

image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:1ee230a6e86d85fe775649c245a015bc661b486979d84f76906a272ecd5be86b
image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:376f2922911113a0e217614e1f0d26672d62258170b7ae1dcad0fdd596e035a6
image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:65388065cdb5614b57090d70850246c1d9072e7af08f710b6126766b1bdf36c5
image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:9c1765bd4934716b6e8221a3eb626e8b427f5d1025be3dbfb4b780d00e198187
image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:a5e9e99889cbe2c4ee96c80d908e80987371b66f9d99c6c6c6155583a9ef505a
image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:afa99e3eed71856cbfed218f50a6d098a57976237253157b2e2b6bfabc874838
image = registry.connect.redhat.com/jfrog/artifactory-operator@sha256:fcbfec1b21e41b9203f05ed82df072f6741dfbae76f998a2c311c25219c01f01
image = registry.connect.redhat.com/jfrog/artifactory-pro@sha256:26129b25cc851b7fcd1b90f26e47470900a4de6db857638deeb06cde5877befa
image = registry.connect.redhat.com/jfrog/artifactory-pro@sha256:97eb6bd2639523ec5f8f7d7e87953ceda515244ef2e7ee4bef08f7eb19faa7ca
image = registry.connect.redhat.com/jfrog/artifactory-pro@sha256:a9bb2467a5fe09a347664130930543a1d902ffec708bc25b0638c3a4fa75dc0c
image = registry.connect.redhat.com/jfrog/artifactory-pro@sha256:ad71e9f1082427f3e9930ba0fd21676feeda22df4b8f210609b8b471aa7ca5f6
image = registry.connect.redhat.com/jfrog/artifactory-pro@sha256:cf846eb2ffd6aaffa033a0d3fa4cd1c029707f97080627c0cd747a7a7a915084
image = registry.connect.redhat.com/jfrog/artifactory-pro@sha256:f0b061c4126f58b70ddaf39a3c5cc009be21b75ac4530ec5088a40d1e6f50e3e
image = registry.connect.redhat.com/jfrog/init@sha256:197f5a1e7a3dd934e72a03a106f0de83e992e6926a774e26483c06fa46faeee5
image = registry.connect.redhat.com/jfrog/init@sha256:a93d4e5afe363edacf3928c510b1a4d82344df71203ae3fc950144d8b0098f5e
image = registry.redhat.io/rhel8/nginx-116@sha256:0ba76a7b26e5ffb95b4354243337ac2b3ff84ae8637c0782631084d1b2f99a33
```


### Build mapping file

```bash
oc adm catalog mirror \
  ${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL} \
  ${LOCAL_REGISTRY} \
  --to-manifests=certified-operators-${SERIAL} \
  --manifests-only \
  -a ${LOCAL_SECRET_JSON} 2>&1 | tee certified-operators.mirror-manifests-only.${SERIAL}.log
```

### Select only jfrog necessary images (basically the list above.)

```bash
grep 'jfrog/artifactory' certified-operators-${SERIAL}/mapping.txt  | tee -a certified-operators-${SERIAL}/mapping.jfrog.txt
grep 'jfrog/init' certified-operators-${SERIAL}/mapping.txt | tee -a certified-operators-${SERIAL}/mapping.jfrog.txt
grep 'rhel8/nginx-116' certified-operators-${SERIAL}/mapping.txt | tee -a certified-operators-${SERIAL}/mapping.jfrog.txt
```

### Mirror the images

```
oc image mirror \
  -a ${LOCAL_SECRET_JSON} \
  --filter-by-os='.*' \
  -f certified-operators-${SERIAL}/mapping.jfrog.txt

oc image mirror \
  -a ${LOCAL_SECRET_JSON} \
  --filter-by-os='.*' \
  registry.connect.redhat.com/jfrog/artifactory-pro:7.10.2-1 \
  ${LOCAL_REGISTRY}/jfrog/artifactory-pro:7.10.2-1

oc image mirror \
  -a ${LOCAL_SECRET_JSON} \
  --filter-by-os='.*' \
  registry.redhat.io/rhel8/nginx-116:latest \
  ${LOCAL_REGISTRY}/rhel8/nginx-116:latest

```

## Apply imageContentSourcePolicy

**optional you can cleanup/filter imageContentSourcePolicy too**

```bash
oc  apply -f certified-operators-${SERIAL}/imageContentSourcePolicy.yaml
```

## Install JFrog Artifactory Enterprise Operator via OperatorHub GUI

Follow the WebUI

## Install JFrog Artifactory Enterprise Operator via OperatorHub CLI

Official documentation [Installing from OperatorHub using the CLI](https://docs.openshift.com/container-platform/4.5/operators/admin/olm-adding-operators-to-cluster.html#olm-installing-operator-from-operatorhub-using-cli_olm-adding-operators-to-a-cluster)

```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshiftartifactoryha-operator
  namespace: openshift-operators
spec:
  channel: alpha
  name: openshiftartifactoryha-operator
  source:  my-certified-operators-${SERIAL}
  sourceNamespace: openshift-marketplace
EOF
```
## Deploy JFrog instance

### Create dummy service to get an internal certificate
```bash
oc apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: jfrog
  annotations:
    service.alpha.openshift.io/serving-cert-secret-name: jfrog-cert
spec:
  ports:
  - name: service-serving-cert
    port: 443
    targetPort: 8443
  selector:
    app: service-serving-cert
EOF
```
### Configure some anyuid privileges

```
oc adm policy add-scc-to-user anyuid -z openshiftartifactoryha-artifactory-ha
```

### Create CR OpenshiftArtifactoryHa

```bash
KEY=$(openssl rand -hex 32)
TARGET_NAMESPACE=demo

oc new-project ${TARGET_NAMESPACE}

NAMESPACE_UID=$(oc get namespace/${TARGET_NAMESPACE} -o jsonpath="{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}" | cut -f1 -d'/')
NAMESPACE_GID=$(oc get namespace/${TARGET_NAMESPACE} -o jsonpath="{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}" | cut -f1 -d'/')

oc apply -f - <<EOF
apiVersion: charts.helm.k8s.io/v1alpha1
kind: OpenshiftArtifactoryHa
metadata:
  name: openshiftartifactoryha
spec:
  artifactory-ha:
    artifactory:
      image:
        registry: ${LOCAL_REGISTRY}
        repository: jfrog/artifactory-pro
        tag: 7.10.2-1
      joinKey: ${KEY}
      masterKey: ${KEY}
      uid: ${NAMESPACE_UID}
      node:
        replicaCount: 2
        waitForPrimaryStartup:
          enabled: false
    databaseUpgradeReady: true
    database:
      driver: org.postgresql.Driver
      password: jfrog
      type: postgresql
      url: jdbc:postgresql://postgresql:5432/jfrog
      user: jfrog
    initContainerImage: >-
      registry.connect.redhat.com/jfrog/init@sha256:a93d4e5afe363edacf3928c510b1a4d82344df71203ae3fc950144d8b0098f5e
    nginx:
      uid: ${NAMESPACE_UID}
      gid: ${NAMESPACE_GID}
      http:
        externalPort: 80
        internalPort: 8080
      https:
        externalPort: 443
        internalPort: 8443
      image:
        registry: ${LOCAL_REGISTRY}
        repository: rhel8/nginx-116
        tag: latest
      service:
        ssloffload: false
      tlsSecretName: jfrog-cert
    postgresql:
      enabled: false
    waitForDatabase: true
EOF
```

### Expose JFrog via an route

```bash
oc expose svc/openshiftartifactoryha-nginx
```

Get the URL:
```bash
$ oc get routes
NAME                           HOST/PORT                                                               PATH   SERVICES                       PORT   TERMINATION   WILDCARD
openshiftartifactoryha-nginx   openshiftartifactoryha-nginx-demo.apps.air-gapped.azure.openshift.pub          openshiftartifactoryha-nginx   http                 None
bash
