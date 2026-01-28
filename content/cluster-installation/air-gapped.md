---
title: Air-gapped installation
linktitle: Air-gapped
weight: 1800
description: An example air-gapped installation
icon: material/lan-disconnect
tags: ['air-gapped', 'disconnected', 'restricted-network']
---
# Air-gapped installation

Official documentation:

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.20.8|
|OpenShift Virt|v4.20.8|

## Download oc client

Download oc client from [cloud.redhat.com](https://cloud.redhat.com/openshift/) or [mirror.openshift.com](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/)

## Create mirror registry

This follows the official documentation: [Chapter 4. Creating a mirror registry with mirror registry for Red Hat OpenShift](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/disconnected_environments/installing-mirroring-creating-registry). **It is just a short wrap up for me.**


### Install mirror-registry

```shell
```


### Download Red Hat pull secret

Download Red Hat pull secret and store it in `redhat-pullsecret.json`



## Apendix

### Docker running a docker registry

Not needed anymore with the mirror-registry, but might be still usefull.

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

## Ressources

* [Creating a mirror registry for installation in a restricted network](https://docs.openshift.com/container-platform/4.2/installing/installing_restricted_networks/installing-restricted-networks-preparations.html)
* [Installing a cluster on bare metal in a restricted network](https://docs.openshift.com/container-platform/4.2/installing/installing\_restricted\_networks/installing-restricted-networks-bare-metal.html)
* [https://github.com/openshift-telco/openshift4x-poc/blob/master/utils/Registry/local-registry.md](https://github.com/openshift-telco/openshift4x-poc/blob/master/utils/Registry/local-registry.md)
* [https://github.com/ashcrow/filetranspiler](https://github.com/ashcrow/filetranspiler)
* [https://github.com/dwojciec/OLM-disconnected](https://github.com/dwojciec/OLM-disconnected)
* [https://github.com/operator-framework/operator-registry](https://github.com/operator-framework/operator-registry)
* [RH-INTERN: Disconnected “Air-gapped” Install Procedure](https://docs.google.com/document/d/10Wu-HRiQEZSdzroXeJKXyjcjcgBHUk3JRBNIpHlEd1A/edit\#)
* [RH-INTERN: OLM Disconnected Install](https://docs.google.com/document/d/1qTxpu_lyNxAH6Xbrqpk3bAj9WtwNH34f16JN4IxzOvg/edit#heading=h.de2g76xqzjd3)

