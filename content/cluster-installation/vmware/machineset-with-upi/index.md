---
title: Use MachineSet with VMware UPI setup
linktitle: MachineSet & UPI
description: TBD
tags:
  - VMware
  - UPI
  - vSphere
  - MachineSet
---
# Use MachineSet with VMware UPI setup

!!! warning
    **Work-in-progress and don't work!**
    Tried with OCP 4.5

WTF: https://access.redhat.com/solutions/5086271


* Create VMware template VM base on 4.5 OVA
* Edit MachineSet
  * Update template (Add VM template name)
  * Update Network Config ( json path: `.spec.template.spec.providerSpec.value.network.devices[0].networkName` )

* Problem in my env: VM start without hostname (localhost) - because dhcp do not send any hostname!
  * Add vSphere IPI Core set the hostname to the VM name in vSphere:
    * [SystemD: vsphere-hostname.service](https://github.com/openshift/machine-config-operator/blob/release-4.5/templates/common/vsphere/units/vsphere-hostname.yaml)
    * [Script: vsphere-hostname.sh](https://github.com/openshift/machine-config-operator/blob/release-4.5/templates/common/vsphere/files/vsphere-hostname.yaml#L19)
  * Those script and service only added if `Infra.Status.PlatformStatus.VSphere.APIServerInternalIP` is set!
  * **"Work-a-round"**: Set the hostname via CLI: `/usr/bin/hostnamectl --transient --static set-hostname XXX`
  * Next problem: Nobody approved  the CSR! If you approve via oc adm certificate approve, the node joins but the machineset didn't recognise.
  * Machine is still in provisioning. (oc get machine)

  * Problem `machine does not have valid node reference` -> https://bugzilla.redhat.com/show_bug.cgi?id=1834966

## Notes during the VMware IPI installation

https://github.com/openshift/installer/blob/master/docs/user/vsphere/install.md

### Install vCenter root ca

```
curl -k -L -O  https://vcenter/certs/download.zip
unzip download.zip
cp -v certs/lin/*  /etc/pki/ca-trust/source/anchors/
update-ca-trust
```

### Bug:

Problem if `basedomain` ends with a `.`...

```
[root@lb 4.5]# ./openshift-install create install-config
? Platform vsphere
? vCenter XXXXX
? Username ocp4-hackfest@e2e.local
? Password [? for help] *****************
INFO Connecting to vCenter XXXXX
INFO Defaulting to only available datacenter: x
INFO Defaulting to only available cluster: x
? Default Datastore xxxx
? Network VM Network
? Virtual IP Address for API xxx
? Virtual IP Address for Ingress xxx
? Base Domain example.com.
X Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alpX Sorry, your reply was invalid: a DNS-1123 subdomain must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character (e.g. 'example.com', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*')
? Cluster Name [? for help]
FATAL failed to fetch Install Config: failed to fetch dependency of "Install Config": failed to generate asset "Cluster Name": interrupt
```