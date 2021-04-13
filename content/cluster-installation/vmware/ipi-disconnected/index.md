---
title: vSphere IPI in a disconnected/air-gapped env.
linktitle: IPI & air-gapped
description: Demo of an vSphere IPI disconnected/air-gapped installation
tags:
  - VMware
  - vSphere
  - air-gapped
  - disconnected
---

# vSphere IPI in a restricted network

## Restricted definition

* disconnected: Cluster has no access to the internet DIRECTLY (firewall rules are in place). They may or maynot have a proxy
* restricted: Cluster has SOME access to the internet (firewall rules allow some but not all). Install may fail. They may or maynot have a proxy
* airgapped. Cluster has NO access to the internet. Full Stop. Not even the router or switches or anything have access. Think of a military install.

## Network overview
```

172.16.0.0/24
172.16.0.4 - jumphost (proxy,ntpd,vcenter)
172.16.0.5 - quay.example.com (registry, dns, dhcp, git-server)

172.16.0.10 - api.infra
172.16.0.11 - *.apps...
```

## Setup suporting infrastructure
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

...

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


```

[root@quay ~]# openshift-install create cluster --dir=infra
INFO Consuming Install Config from target directory
INFO Obtaining RHCOS image file from 'https://releases-art-rhcos.svc.ci.openshift.org/art/storage/releases/rhcos-4.7/47.83.202102090044-0/x86_64/rhcos-47.83.202102090044-0-vmware.x86_64.ova?sha256=13d92692b8eed717ff8d0d113a24add339a65ef1f12eceeb99dabcd922cc86d1'
FATAL failed to fetch Terraform Variables: failed to generate asset "Terraform Variables": failed to get vsphere Terraform variables: failed
to use cached vsphere image: Get "https://releases-art-rhcos.svc.ci.openshift.org/art/storage/releases/rhcos-4.7/47.83.202102090044-0/x86_64/rhcos-47.83.202102090044-0-vmware.x86_64.ova?sha256=13d92692b8eed717ff8d0d113a24add339a65ef1f12eceeb99dabcd922cc86d1": dial tcp: lookup releases-art-rhcos.svc.ci.openshift.org on 172.16.0.5:53: server misbehaving


openshift-install explain installconfig.platform.vsphere.clusterOSImage
KIND:     InstallConfig
VERSION:  v1

RESOURCE: <string>
  ClusterOSImage overrides the url provided in rhcos.json to download the RHCOS OVA

```

### Post installation

#### Configure image registry

--8<-- "content/cluster-configuration/image-registry/vsphere-registry.md"


#### NTP

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

#### Disable catalog sources

https://docs.openshift.com/container-platform/4.7/operators/admin/olm-restricted-networks.html#olm-restricted-networks-operatorhub_olm-restricted-networks

```
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
```


#### Registry search path & ca

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

### Operator installation


 * <https://bugzilla.redhat.com/show_bug.cgi?id=1874106>

```
export OCP_RELEASE=4.7.0
export LOCAL_REGISTRY='quay.example.com'
export LOCAL_REPOSITORY='infra/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64
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

 * Check upgrade path: <https://access.redhat.com/labs/ocpupgradegraph/update_path> 
 * Mirror images again - new version
 * Run oc adm oc adm upgrade --to ..

#### OpenShift Update Service

https://www.openshift.com/blog/openshift-update-service-update-manager-for-your-cluster



### Pipeline demo

<https://docs.openshift.com/container-platform/4.7/cicd/pipelines/creating-applications-with-cicd-pipelines.html#creating-pipeline-tasks_creating-applications-with-cicd-pipelines>

```
oc create -f http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/01_apply_manifest_task.yaml
oc create -f http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/02_update_deployment_task.yaml



oc create -f http://quay.example.com:3000/openshift/pipelines-tutorial/raw/pipelines-1.3/01_pipeline/04_pipeline.yaml
```



#### Mirroring images to run pipelines in a restricted environment

https://docs.openshift.com/container-platform/4.7/cicd/pipelines/creating-applications-with-cicd-pipelines.html#op-mirroring-images-to-run-pipelines-in-restricted-environment_creating-applications-with-cicd-pipelines

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

**Problem**

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
