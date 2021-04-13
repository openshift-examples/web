---
title: OpenShift.tv - vSphere IPI in a disconnected environment
linktitle: vSphere IPI & disconnected environment
description: Demo of an vSphere IPI disconnected/air-gapped installation
tags:
  - VMware
  - vSphere
  - air-gapped
  - restriced
  - disconnected
  - OpenShiftTV
---

# vSphere IPI & disconnected environment

!!! note
    This is **not** a complete documentation or copy & past ready documentation!
    At least speaker notes or my personal notes, highlight only some key points.
    A complete documentation is available at [docs.openshift.com](https://docs.openshift.com) or [docs.redhat.com](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.7/)

## Recording

TBD - after the session

## Definition

* **disconnected**: Cluster has no access to the internet DIRECTLY (firewall rules are in place). They may or maynot have a proxy.
* **restricted**: Cluster has SOME access to the internet (firewall rules allow some but not all). Install may fail. They may or maynot have a proxy. *Term used in the documentation!*
* **airgapped**. Cluster has NO access to the internet. Full Stop. Not even the router or switches or anything have access. Think of a military install.

Kudos to [Christian Hernandez](https://twitter.com/christianh814)

## Lab information

 * vSphere 7
 * Domain: example.com
 * Network: `172.16.0.0/24`
    * `172.16.0.4   ` - jumphost-disconnected.example.com (proxy in the env., ntpd,
      vcenter forwarder)
    * `172.16.0.5   ` - quay.example.com (image registry, dns, dhcp, git-server,
      httpd)
    * VIPS:
      * `172.16.0.10` - api.infra.example.com
      * `172.16.0.11` - *.apps.infra.example.com
      * `172.16.0.12` - api.demo1.example.com
      * `172.16.0.13` - *.apps.demo1.example.com
      * `172.16.0.14` - api.demo1.example.com
      * `172.16.0.15` - *.apps.demo1.example.com

## Overview

 * OpenShift installation
    * Mirror release images
    * Mirror rhcos ova
    * Prepare install-config.yaml
        * Important: imageContentSources 🔴, additionalTrustBundle,
          platform.vsphere.clusterOSImage (check `openshift-install explain`)
    * Run installation
 * OpenShift post-installation steps
    * [Configure registry search path & ca](#configure-registry-search-path-ca) 💡
 * OperatorHub / OLM
    * Disable default catalog sources
    * Create operator index
    * Mirror operator images
    * Apply operator source & imageContentSourcePolicy
 * OpenShift Upgrade
    * [Check update path](https://access.redhat.com/labs/ocpupgradegraph/update_path)
    * Mirror release image & image signature
    * Run upgrade via cli
    * Futur: [OpenShift Update Service](https://www.openshift.com/blog/openshift-update-service-update-manager-for-your-cluster)
 * Demo: Run a pipeline
    * OpenShift Pipeline operator is synced and installed
    * Copy all necessary git resources into your own git-server
    * Mirror all necessary container images
    * [Run the pipeline and fail because of missing pip mirror](#problem) 🔴

## Documentation & use-full resources

 * [Installing a cluster on vSphere in a restricted network](https://docs.openshift.com/container-platform/4.7/installing/installing_vsphere/installing-restricted-networks-installer-provisioned-vsphere.html)
 * [Updating a restricted network cluster](https://docs.openshift.com/container-platform/4.7/updating/updating-restricted-network-cluster.html)
 * [Using Operator Lifecycle Manager on restricted networks](https://docs.openshift.com/container-platform/4.7/operators/admin/olm-restricted-networks.html)
 * [Creating CI/CD solutions for applications using OpenShift Pipelines](https://docs.openshift.com/container-platform/4.7/cicd/pipelines/creating-applications-with-cicd-pipelines.html#creating-pipeline-tasks_creating-applications-with-cicd-pipelines)
 * [OpenShift Update Path](https://access.redhat.com/labs/ocpupgradegraph/update_path)
 * [OpenShift Update Service](https://www.openshift.com/blog/openshift-update-service-update-manager-for-your-cluster)
 * [Container images, multi-architecture, manifests, ids, digests – what’s behind?](https://www.opensourcerers.org/2020/11/16/container-images-multi-architecture-manifests-ids-digests-whats-behind/)

## OpenShift Installation

### Mirror relrease images

```bash

$ cat env.sh
export OCP_RELEASE=4.7.0
export LOCAL_REGISTRY='quay.example.com'
export LOCAL_REPOSITORY='infra/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64

$ ./env.sh

$ oc adm release mirror  -a ${LOCAL_SECRET_JSON} \
  --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
  --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
  --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

....
imageContentSources:
- mirrors:
  - quay.example.com/infra/openshift4
  source: quay.io/openshift-release-dev/ocp-release- mirrors:
  - quay.example.com/infra/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev

```



### Install OpenShift

Example install-config
```yaml hl_lines="37 39-46 48-55"
apiVersion: v1
baseDomain: example.com
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform: {}
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}  replicas: 3metadata:
  creationTimestamp: null
  name: infra
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  vsphere:
    apiVIP: 172.16.0.10
    cluster: lab
    datacenter: DC
    defaultDatastore: datastore
    ingressVIP: 172.16.0.11
    network: Disconnected
    password: xxx
    username: xxx
    vCenter: vcenter.example.com
    folder: /DC/vm/rbohne/
    clusterOSImage: http://quay.example.com:8080/rhcos-4.7.0-x86_64-vmware.x86_64.ova?sha256=13d92692b8eed717ff8d0d113a24add339a65ef1f12eceeb99dabcd922cc86d1
publish: External
imageContentSources:
- mirrors:
  - quay.example.com/infra/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - quay.example.com/infra/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
pullSecret: '{"auths":{"quay.example.com":{"auth":"YWRtaW46cmVkaGF0MDI="}}}'
sshKey: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCu9AV3k/ktphogW+Y28fZ0R+ncTxtXalVmpGjvZCuARZJQcgA72pNnXSvrTadJo5D48LgXOz5BwZnoml0toPkLVKBa4fU6kvQsQHDzvElpKbBH8/tmYRV72wt2kJjAS//Ycu9qz2scK+YAdjyle+WUh0qyEzgKKkLjwUmdZOYfJ0eZP+Jl5ljeXk3olCcAQc7JaBr3umREr5o/3+wnHsYPlOGZoSvGRTuEy81tQTL+Nl12LrN1ZxZQZ8jzIExIGRvk8/F2oufFfCigXkEiMf+8l2WXDVR/MGLVhEyle2tJAczBwaskh1nJFKfK6H88lm0fyVev9++GYClSvIxjBWmD88s09cei6C4gRSKANtANmtoOUNhVGcFXaJSPHnrOo7bKnU7XNAcmEZZtUuB05Oc1lJSNoBB9wDj65hzvWnyvQ/zgXeSmUjHObArZ054qPtscIV5QGQUdgVsRCgPWS9SlmYMje9O8AJe+Kqye3ykyMeRDZEUNvO+9Pg+ZGbgH7eM= root@jumphost-disconnected.localdomain"
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  MIIEQzCCAyugAwIBAgIUVwbzbrQNDW3tU2xdZDVsF5VzTlEwDQYJKoZIhvcNAQEL
  BQAwgagxCzAJBgNVBAYTAkRFMRAwDgYDVQQIDAdCYXZhcmlhMQ8wDQYDVQQHDAZN
    ....
  qGE5LlcUuR0SCO8yVcILcaiXhxGzqYlOZK26u4APntWyn4eUGuLpiReimgE4NvZr
  ZYDgBfQ2I9ulhe0dAScUJz0c8iErjpJJ9kT0Ebar/UuPGQvyOnvM
  -----END CERTIFICATE-----
```

Run `openshift-install create cluster`

### Post installation

#### Configure registry search path & ca


<https://docs.openshift.com/container-platform/4.7/openshift_images/image-configuration.html>

```bash
oc create configmap additional-trusted-ca \
  --from-file=quay.example.com=/etc/pki/ca-trust/source/anchors/quay.ca.crt \
  -n openshift-config

oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: Image
metadata:
  name: cluster
spec:
  allowedRegistriesForImport:
    - domainName: quay.example.com
      insecure: false
    # If not added update will fail
    #  oc logs -n openshift-cluster-version -l k8s-app=cluster-version-operator
    # I0413 08:12:21.986805       1 reflector.go:530] github.com/openshift/client-go/config/informers/externalversions/factory.go:101: Watch close - *v1.Proxy total 0 items received
    #E0413 08:12:22.072266       1 task.go:112] error running apply for imagestream "openshift/cli" (378 of 668): ImageStream.image.openshift.io "cli" is invalid: spec.tags[latest].from.name: Forbidden: registry "quay.io" not allowed by whitelist: "image-registry.openshift-image-registry.svc:5000", "quay.example.com:443"
    #I0413 08:12:24.705418       1 leaderelection.go:273] successfully renewed lease openshift-cluster-version/version
    - domainName: quay.io
      insecure: false
  additionalTrustedCA:
    name: additional-trusted-ca
  registrySources:
    containerRuntimeSearchRegistries:
    - quay.example.com
    allowedRegistries:
    - quay.example.com
    - registry.redhat.io
    - quay.io
    - registry.access.redhat.com
    - image-registry.openshift-image-registry.svc:5000
EOF

```


#### Disable catalog sources

<https://docs.openshift.com/container-platform/4.7/operators/admin/olm-restricted-networks.html#olm-restricted-networks-operatorhub_olm-restricted-networks>

```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```

#### Configure image registry

--8<-- "content/cluster-configuration/image-registry/vsphere-registry.md"

#### Configure NTP

```
chronybase64=$(cat << EOF | base64 -w 0
server 172.16.0.4 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
keyfile /etc/chrony.keys
leapsectz right/UTC
logdir /var/log/chrony
EOF
)

oc apply -f - << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: worker
  name: 50-worker-chrony
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${chronybase64}
        filesystem: root
        mode: 0644
        path: /etc/chrony.conf
EOF


oc apply -f - << EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 50-master-chrony
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,${chronybase64}
        filesystem: root
        mode: 0644
        path: /etc/chrony.conf
EOF

```

### Operator installation


 * <https://bugzilla.redhat.com/show_bug.cgi?id=1874106>

```
source env.sh
export REG_CREDS=${XDG_RUNTIME_DIR}/containers/auth.json

# Login into all registries...



podman run -p50051:50051 \
     -it registry.redhat.io/redhat/redhat-operator-index:v4.7

opm index prune \
    -f registry.redhat.io/redhat/redhat-operator-index:v4.7 \
    -p advanced-cluster-management \
    -t quay.example.com/infra/redhat-operator-index:v4.7


grpcurl -plaintext localhost:50051 api.Registry/ListPackages > packages.out

 grep -E '(advanc|pipeline)' packages.out


opm index prune \
    -f registry.redhat.io/redhat/redhat-operator-index:v4.7 \
    -p advanced-cluster-management,openshift-pipelines-operator-rh,web-terminal   \
    -t quay.example.com/infra/redhat-operator-index:v4.7

podman push quay.example.com/infra/redhat-operator-index:v4.7

$ oc adm catalog mirror \
  -a ${REG_CREDS} \
  --manifests-only \
  --index-filter-by-os='.*' \
  quay.example.com/infra/redhat-operator-index:v4.7 \
  quay.example.com/infra
src image has index label for database path: /database/index.db
using database path mapping: /database/index.db:/tmp/353326806
wrote database to /tmp/353326806
using database at: /tmp/353326806/index.db
no digest mapping available for quay.example.com/infra/redhat-operator-index:v4.7, skip writing to ImageContentSourcePolicy
wrote mirroring manifests to manifests-redhat-operator-index-1618230619

cd manifests-redhat-operator-index-1618230619



oc image mirror \
  --skip-multiple-scopes=true \
  -a ${REG_CREDS} \
  --filter-by-os='.*' \
  -f mapping.txt


```


### Cluster upgrade

<https://docs.openshift.com/container-platform/4.7/updating/updating-restricted-network-cluster.html>

 * Check upgrade path: <https://access.redhat.com/labs/ocpupgradegraph/update_path>
 * Mirror images again - new version
 * Run oc adm oc adm upgrade --to ..

#### Mirror

```
source env.sh
export OCP_RELEASE=4.7.2

oc adm release mirror  -a ${LOCAL_SECRET_JSON} \
  --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}  \
  --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
  --apply-release-image-signature
....

```

#### Update command

```

oc adm release info -a $REG_CREDS quay.example.com/infra/openshift4:4.7.2-x86_64 | grep 'Pull From'
Pull From: quay.example.com/infra/openshift4@sha256:83fca12e93240b503f88ec192be5ff0d6dfe750f81e8b5ef71af991337d7c584
oc adm upgrade --allow-explicit-upgrade --to-image quay.example.com/infra/openshift4@sha256:83fca12e93240b503f88ec192be5ff0d6dfe750f81e8b5ef71af991337d7c584

```

#### OpenShift Update Service

https://www.openshift.com/blog/openshift-update-service-update-manager-for-your-cluster


## Demo: Run a pipeline

[Creating Pipeline Tasks](https://docs.openshift.com/container-platform/4.7/cicd/pipelines/creating-applications-with-cicd-pipelines.html#creating-pipeline-tasks_creating-applications-with-cicd-pipelines)

```
oc create -f http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/01_apply_manifest_task.yaml
oc create -f http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/02_update_deployment_task.yaml



oc create -f http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/04_pipeline.yaml
```



#### Mirroring images to run pipelines in a restricted environment

[Mirroring images to run pipelines in a restricted environment](https://docs.openshift.com/container-platform/4.7/cicd/pipelines/creating-applications-with-cicd-pipelines.html#op-mirroring-images-to-run-pipelines-in-restricted-environment_creating-applications-with-cicd-pipelines)

```

oc image mirror -a $REG_CREDS registry.redhat.io/ubi8/python-38:latest quay.example.com/ubi8/python-38:latest
oc image mirror -a $REG_CREDS registry.redhat.io/ubi8/go-toolset:1.14.7 quay.example.com/ubi8/go-toolset

oc tag quay.example.com/ubi8/python-38:latest python:latest --scheduled -n openshift
oc tag quay.example.com/ubi8/go-toolset:1.14.7  golang:latest --scheduled -n openshift

oc tag quay.example.com/infra/openshift4:4.7.0-x86_64-cli cli:latest --scheduled -n openshift

```


#### Run pipeline

```
tkn pipeline start build-and-deploy \
  -w name=shared-workspace,volumeClaimTemplateFile=http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/03_persistent_volume_claim.yaml \
  -p deployment-name=vote-api \
  -p git-url=http://quay.example.com:3000/openshift-pipelines/vote-api.git \
  -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipeline/vote-api

tkn pipeline start build-and-deploy \
  -w name=shared-workspace,volumeClaimTemplateFile=http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/03_persistent_volume_claim.yaml \
  -p deployment-name=vote-ui \
  -p git-url=http://quay.example.com:3000/openshift-pipelines/vote-ui.git \
  -p IMAGE=image-registry.openshift-image-registry.svc:5000/pipeline/vote-ui

```

##### Problem

```
[build-image : build] WARNING: Retrying (Retry(total=4, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.VerifiedHTTPSConnection object at 0x7fdf07b05c10>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/flask/
[build-image : build] WARNING: Retrying (Retry(total=3, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.VerifiedHTTPSConnection object at 0x7fdf07b05280>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/flask/
[build-image : build] WARNING: Retrying (Retry(total=2, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.VerifiedHTTPSConnection object at 0x7fdf07b05520>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/flask/
[build-image : build] WARNING: Retrying (Retry(total=1, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.VerifiedHTTPSConnection object at 0x7fdf07b050d0>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/flask/
[build-image : build] WARNING: Retrying (Retry(total=0, connect=None, read=None, redirect=None, status=None)) after connection broken by 'NewConnectionError('<pip._vendor.urllib3.connection.VerifiedHTTPSConnection object at 0x7fdf07afaf40>: Failed to establish a new connection: [Errno -2] Name or service not known')': /simple/flask/
[build-image : build] ERROR: Could not find a version that satisfies the requirement Flask (from -r requirements.txt (line 1)) (from versions: none)
[build-image : build] ERROR: No matching distribution found for Flask (from -r requirements.txt (line 1))
[build-image : build] subprocess exited with status 1
[build-image : build] subprocess exited with status 1
[build-image : build] error building at STEP "RUN pip install -r requirements.txt": exit status 1
[build-image : build] level=error msg="exit status 1"

```

Solution: You have to mirror....

## Appendix - Setup supporting infrastructure
### Setup quay

[Deploy Red Hat Quay for proof-of-concept (non-production) purposes](https://access.redhat.com/documentation/en-us/red_hat_quay/3.4/html-single/deploy_red_hat_quay_for_proof-of-concept_non-production_purposes/index)

### Setup Git-server

```
mkdir /home/gogs
cat > /etc/systemd/system/gogs.service <<EOF
[Unit]
Description=gogs
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm gogs
ExecStart=/usr/bin/podman run --name gogs \
  -p 2222:22 \
  -p 3000:3000 \
  -v /home/gogs:/data:Z \
  docker.io/gogs/gogs:latest

ExecReload=-/usr/bin/podman stop gogs
ExecReload=-/usr/bin/podman rm gogs
ExecStop=-/usr/bin/podman stop gogs
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
```

### DNS & dhcp

Skiped, straigt foroward dnsmasq:
```
[root@quay ~]# cat /etc/dnsmasq.d/openshift-4.conf
#strict-order
domain=example.com
#expand-hosts
# Dynamisches DHCP
dhcp-range=172.16.0.100,172.16.0.199,12h

address=/api.infra.example.com/172.16.0.10address=/apps.infra.example.com/172.16.0.11

address=/api.demo1.example.com/172.16.0.12
address=/apps.demo1.example.com/172.16.0.13
```


