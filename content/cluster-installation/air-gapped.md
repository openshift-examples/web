---
title: Air-gapped installation
linktitle: Air-gapped
weight: 1800
description: TBD
tags:
  - air-gapped
  - disconnected
  - restricted-network
---
# Air-gapped installation

## Download oc client

Download oc client from [cloud.redhat.com](https://cloud.redhat.com/openshift/) or [mirror.openshift.com](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/)

## Create mirror registry

This follows the official documentation: [Creating a mirror registry for installation in a restricted network](https://docs.openshift.com/container-platform/latest/installing/install_config/installing-restricted-networks-preparations.html). **It is just a short wrap up for me.**

### Install & prepare image registry
```bash
yum -y install podman httpd-tools

mkdir -p /var/lib/libvirt/images/mirror-registry/{auth,certs,data}

openssl req -newkey rsa:4096 -nodes -sha256 \
  -keyout /var/lib/libvirt/images/mirror-registry/certs/domain.key \
  -x509 -days 365 -subj "/CN=host.compute.local" \
  -out /var/lib/libvirt/images/mirror-registry/certs/domain.crt

cp -v /var/lib/libvirt/images/mirror-registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust

htpasswd -bBc /var/lib/libvirt/images/mirror-registry/auth/htpasswd admin r3dh4t\!1
```

Create internal registry service: `/etc/systemd/system/mirror-registry.service`

**Change REGISTRY_HTTP_ADDR in case you use different network**

```
cat - > /etc/systemd/system/mirror-registry.service <<EOF
[Unit]
Description=Mirror registry (mirror-registry)
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m

ExecStartPre=-/usr/bin/podman rm "mirror-registry"
ExecStartPre=/usr/bin/podman pull quay.io/redhat-emea-ssa-team/registry:2
ExecStart=/usr/bin/podman run --name mirror-registry --net host \
  -v /var/lib/libvirt/images/mirror-registry/data:/var/lib/registry:z \
  -v /var/lib/libvirt/images/mirror-registry/auth:/auth:z \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_HTTP_ADDR=192.168.50.1:5000" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=registry-realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  -e "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=TRUE" \
  -v /var/lib/libvirt/images/mirror-registry/certs:/certs:z \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true \
  quay.io/redhat-emea-ssa-team/registry:2

ExecReload=-/usr/bin/podman stop "mirror-registry"
ExecReload=-/usr/bin/podman rm "mirror-registry"
ExecStop=-/usr/bin/podman stop "mirror-registry"
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start mirror registry
```
systemctl enable --now mirror-registry.service
systemctl status mirror-registry.service
```

Configure firewall for Centos or RHEL
```
firewall-cmd --zone=public --permanent --add-port=5000/tcp
firewall-cmd --reload
```

Check registry
```
$ curl -u admin:r3dh4t\!1 https://host.compute.local:5000/v2/_catalog
{"repositories":[]}
```

Create mirror registry pullsecret
```
podman login --authfile mirror-registry-pullsecret.json host.compute.local:5000
```

### Download Red Hat pull secret

Download Red Hat pull secret and store it in `redhat-pullsecret.json`

### Mirror images

Merge  mirror-registry-pullsecret.json & redhat-pullsecret.json
```
jq -s '{"auths": ( .[0].auths + .[1].auths ) }' mirror-registry-pullsecret.json redhat-pullsecret.json > pullsecret.json
```

Mirror images:
```
export OCP_RELEASE=$(oc version -o json  --client | jq -r '.releaseClientVersion')
export LOCAL_REGISTRY='host.compute.local:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64
# export REMOVABLE_MEDIA_PATH=<path>

# Try run:

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run

oc adm -a ${LOCAL_SECRET_JSON} release mirror \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

```

Save the output:
```
info: Mirroring completed in 57.1s (81.95MB/s)

Success
Update image:  host.compute.local:5000/ocp4/openshift4:4.2.0
Mirror prefix: host.compute.local:5000/ocp4/openshift4

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - host.compute.local:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - host.compute.local:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - host.compute.local:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - host.compute.local:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
```

Extract openshift-install command
```
oc adm release extract -a pullsecret.json --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"
```

Check openshift-install version:
```
$ ./openshift-install version
./openshift-install 4.5.2
built from commit 6336a4b3d696dd898eed192e4188edbac99e8c27
release image host.compute.local:5000/ocp4/openshift4@sha256:8f923b7b8efdeac619eb0e7697106c1d17dd3d262c49d8742b38600417cf7d1d
```



## Ressources

* [Creating a mirror registry for installation in a restricted network](https://docs.openshift.com/container-platform/4.2/installing/installing_restricted_networks/installing-restricted-networks-preparations.html)
* [Installing a cluster on bare metal in a restricted network](https://docs.openshift.com/container-platform/4.2/installing/installing\_restricted\_networks/installing-restricted-networks-bare-metal.html)
* [https://github.com/openshift-telco/openshift4x-poc/blob/master/utils/Registry/local-registry.md](https://github.com/openshift-telco/openshift4x-poc/blob/master/utils/Registry/local-registry.md)
* [https://github.com/ashcrow/filetranspiler](https://github.com/ashcrow/filetranspiler)
* [https://github.com/dwojciec/OLM-disconnected](https://github.com/dwojciec/OLM-disconnected)
* [https://github.com/operator-framework/operator-registry](https://github.com/operator-framework/operator-registry)
* [RH-INTERN: Disconnected “Air-gapped” Install Procedure](https://docs.google.com/document/d/10Wu-HRiQEZSdzroXeJKXyjcjcgBHUk3JRBNIpHlEd1A/edit\#)
* [RH-INTERN: OLM Disconnected Install](https://docs.google.com/document/d/1qTxpu_lyNxAH6Xbrqpk3bAj9WtwNH34f16JN4IxzOvg/edit#heading=h.de2g76xqzjd3)

