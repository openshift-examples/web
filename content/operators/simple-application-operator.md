---
title: Simple Application Operator - WiP
linktitle: Simple Application Operator - WiP
weight: 12600
description: TBD
render_macros: false
---

# Draft/WIP Simple example ansible operator

```
operator-sdk new simple-application-operator \
  --api-version=simple.application.openshift.pub/v1  \
  --kind=SimpleApp \
  --type=ansible

operator-sdk build quay.io/rbo/demo-http-operator:latest
docker push quay.io/rbo/demo-http-operator:latest

sed -i "" 's|{{ REPLACE_IMAGE }}|quay.io/rbo/demo-http-operator:latest|g' deploy/operator.yaml
sed -i "" 's|{{ pull_policy\|default('\''Always'\'') }}|Always|g' deploy/operator.yaml

oc new-project simple-application-operator
# Setup Service Account
oc create -f deploy/service_account.yaml
# Setup RBAC
oc create -f deploy/role.yaml
oc create -f deploy/role_binding.yaml
# Setup the CRD
oc create -f deploy/crds/simple.application.openshift.pub_simpleapps_crd.yaml
# Deploy the app-operator
oc create -f deploy/operator.yaml

# Create an AppService CR
# The default controller will watch for AppService objects and create a pod for each CR
oc create -f deploy/crds/simple.application.openshift.pub_v1_simpleapp_cr.yaml
```

# Redeploy
```
operator-sdk build quay.io/rbo/demo-http-operator:latest
docker push quay.io/rbo/demo-http-operator:latest
oc delete pods -l name=simple-application-operator
```

# Build csv
Version operator-sdk version: "v0.15.2",

```
operator-sdk generate csv \
  --csv-version 0.1.0 \
  --operator-name simple-application-operator \
  --verbose
```

**???**
```
./operator-sdk-v0.12.0-x86_64-apple-darwin olm-catalog gen-csv --csv-version 0.1.0
INFO[0000] Generating CSV manifest version 0.1.0
INFO[0000] Fill in the following required fields in file deploy/olm-catalog/simple-application-operator/0.1.0/simple-application-operator.v0.1.0.clusterserviceversion.yaml:
	spec.keywords
	spec.maintainers
	spec.provider
INFO[0000] Created deploy/olm-catalog/simple-application-operator/0.1.0/simple-application-operator.v0.1.0.clusterserviceversion.yaml
INFO[0000] Created deploy/olm-catalog/simple-application-operator/simple-application-operator.package.yaml
```

# Prepare bundle - Ugly! Why? TODO!

```
rm -rf prep-bundle
mkdir prep-bundle/
cp -v  deploy/*yaml deploy/crds/*crd.yaml deploy/olm-catalog/*/*/*.clusterserviceversion.yaml prep-bundle/
```

# Build bundle
An Operator Bundle is built as a scratch (non-runnable) container image that contains operator manifests and specific metadata in designated directories inside the image.
[Source](https://github.com/operator-framework/operator-registry/blob/master/docs/design/operator-bundle.md#operator-bundle-overview)

## Options 1) use operator sdk (v0.15.2) bundle create
```
operator-sdk bundle create \
    --package simple-application-operator \
    --channels stable,beta \
    --default-channel stable \
    --directory deploy/olm-catalog/simple-application-operator/ \
    quay.io/rbo/demo-http-bundle:v0.1.0

docker push quay.io/rbo/demo-http-bundle:v0.1.0
```

## Option 2) use opm version v1.5.9

[Documention](https://github.com/operator-framework/operator-registry/blob/master/docs/design/operator-bundle.md#build-bundle-image)

```
./opm alpha bundle build \
    --directory prep-bundle/ \
    --tag quay.io/rbo/demo-http-bundle:v0.1.0 \
    --package simple-application-operator \
    --channels stable,beta \
    --default stable
docker push quay.io/rbo/demo-http-bundle:v0.1.0

```

# OPM - put manifest into bundle
```
./opm index add --container-tool docker --bundles quay.io/rbo/demo-http-bundle:v0.1.0 --tag  quay.io/rbo/demo-http-catalog-index:v0.0.1
INFO[0000] building the index                            bundles="[quay.io/rbo/demo-http-operator:v0.1.0]"
INFO[0000] running docker pull                           img="quay.io/rbo/demo-http-operator:v0.1.0"
INFO[0002] running docker save                           img="quay.io/rbo/demo-http-operator:v0.1.0"
INFO[0002] loading Bundle quay.io/rbo/demo-http-operator:v0.1.0  img="quay.io/rbo/demo-http-operator:v0.1.0"
INFO[0002] found annotations file searching for csv      dir=bundle_tmp261748450 file=bundle_tmp261748450/metadata load=annotations
FATA[0002] permissive mode disabled                      bundles="[quay.io/rbo/demo-http-operator:v0.1.0]" error="error loading bundle from image: no csv found in bundle"
```
https://github.com/operator-framework/operator-registry/releases/download/v1.5.9/darwin-amd64-opm

**FAIL WITH:  **
```
FROM quay.io/operator-framework/upstream-registry-builder AS builder
....
Error: error building at STEP "COPY --from=builder /build/bin/opm /opm": no files found matching "/var/lib/containers/storage/overlay/f33d0f91af5f71963c55a31f7b941fb4da13585df10bcdd7b49b182cbfd50ba9/merged/build/bin/opm": no such file or directory
. exit status 125
```

Work-a-round
```
./opm index add --container-tool docker --binary-image quay.io/operator-framework/upstream-registry-builder --bundles quay.io/rbo/demo-http-bundle:v0.1.0 --tag  quay.io/rbo/demo-http-catalog-index:v0.0.1 --generate
# Change index.Dockerfile
# - COPY --from=builder /build/bin/opm /opm
# + COPY --from=builder /build/bin/linux-amd64-opm /opm

docker build -t quay.io/rbo/demo-http-catalog-index:v0.0.1 -f index.Dockerfile .
docker push quay.io/rbo/demo-http-catalog-index:v0.0.1
```

# Test catalog index
```
docker run -p 50051:50051 -ti quay.io/rbo/demo-http-catalog-index:v0.0.1

grpcurl -plaintext  localhost:50051 api.Registry/ListPackages
grpcurl -plaintext -d '{"name":"simple-application-operator"}' localhost:50051 api.Registry/GetPackage
{
  "name": "simple-application-operator",
  "channels": [
    {
      "name": "beta",
      "csvName": "simple-application-operator.v0.1.0"
    },
    {
      "name": "stable",
      "csvName": "simple-application-operator.v0.1.0"
    }
  ],
  "defaultChannelName": "stable"
}

```
# Add to OpenShift


# Notes & Resources

* https://github.com/operator-framework/operator-sdk/blob/master/doc/ansible/dev/finalizers.md
* https://operator-framework.github.io/olm-book/
