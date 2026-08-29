---
title: Virtual BMC
linktitle: Virtual BMC
description: Virtual BMC with VM's on KubeVirt / OCP-V
tags: ['cnv', 'kubevirt','ocp-v','v4.18','bmc','fakefish']
---
# Virtual BMC with VM's on KubeVirt / OCP-V

Two options available, lets go with fakefish:

* https://github.com/starbops/kubevirtbmc
* NEW: https://github.com/v1k0d3n/kubevirt-redfish
* https://github.com/openshift-metal3/fakefish/tree/main/kubevirt_scripts

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18|
|OpenShift Virt|v4.18|

## Simple single VM example

```shell
export HOST="ff-node-oi5cyy-rbohne-fakefish.apps.isar.coe.muc.redhat.com"
export ISO_URL=http://tinycorelinux.net/16.x/x86/release/Core-current.iso

curl -s https://$HOST/redfish/v1/Systems | jq -r

curl -s https://$HOST/redfish/v1/Managers/1/VirtualMedia/Cd | jq  '[{iso_connected: .Inserted}]'


curl -d \
    '{"Image":"'"$ISO_URL"'", "Inserted": true}' \
     -H "Content-Type: application/json" \
     -X POST \
     https://$HOST/redfish/v1/Managers/1/VirtualMedia/Cd/Actions/VirtualMedia.InsertMedia


curl -s -d '{"ResetType":"Off"}' \
    -H "Content-Type: application/json" -X POST \
    https://$HOST/redfish/v1/Systems/1/Actions/ComputerSystem.Reset


```

