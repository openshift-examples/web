---
title: Appliance
linktitle: Appliance
description: Appliance
tags: ['appliance','air-gapped']
---
# Some information

```bash
curl -L -O https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/4.16.27/openshift-install-linux-4.16.27.tar.gz
tar xzvf openshift-install-linux-4.16.27.tar.gz
export APPLIANCE_IMAGE="quay.io/edge-infrastructure/openshift-appliance"
export APPLIANCE_ASSETS="$(pwd)/appliance_assets"
mkdir -p $APPLIANCE_ASSETS
podman run --rm -it --pull newer -v $APPLIANCE_ASSETS:/assets:Z $APPLIANCE_IMAGE generate-config
...
podman run --rm -it --pull newer --privileged --net=host -v $APPLIANCE_ASSETS:/assets:Z $APPLIANCE_IMAGE build
```
