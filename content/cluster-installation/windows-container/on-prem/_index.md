---
title:  On-Prem Windows Container installation
linktitle: On-Prem - WiP
description: On-Prem Windows Container installation
---
# On-Prem Windows Container installation

!!! warning
    Work in progress, this is no finish yet!
    **And will not work!!!**

## Requirements:

Download:

 - [Windows 2019 Server](https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2019) **The English Version!**
 - On KVM: [Latest VirtIO driver](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.185-2/virtio-win-0.1.185.iso)

## Windows installation

!!! note
    Windows Container need enabled Hyper-V, that means you have to enable nested virtualization. KVM on Host (L0) and Windows 2019 + Hyper-V as VM (L1) will fail. Windows crash/stuck at boot after Hyper-V activation

### Installation on KVM (will fail because if nested Hyper-V!)

List of  Disk is empty, please install VirtIO driver:

![Load virtIO driver](load-virtIO-driver.png "Load virtIO driver")

![Select VirtIO](select-virtIO.png "Select VirtIO")

![Select Windows Server Datacenter with Desktop](select-windows-datacenter-with-gui.png "Select Windows Server Datacenter with Desktop")

### Install VM guest tools (VirtIO/VMware)


#### VirtIO
Important: Use latest upstream because of:

![VirtIO Error](rhel-virtio-error.png "VirtIO Error")

### Enable Remote Desktop (Optional)

### Enable Hyper-V

 * **1**
   ![HyperV Step 1](hyper-v-1.png "HyperV Step 1")
 * **2**
   ![HyperV Step 2](hyper-v-2.png "HyperV Step 2")
 * **3**
   ![HyperV Step 3](hyper-v-3.png "HyperV Step 3")
 * **4**
   ![HyperV Step 4](hyper-v-4.png "HyperV Step 4")
 * **5**
   ![HyperV Step 5](hyper-v-5.png "HyperV Step 5")
 * **6**
   ![HyperV Step 6](hyper-v-6.png "HyperV Step 6")
 * **7**
   ![HyperV Step 7](hyper-v-7.png "HyperV Step 7")
 * **8**
   ![HyperV Step 8](hyper-v-8.png "HyperV Step 8")
 * **9**
   ![HyperV Step 9](hyper-v-9.png "HyperV Step 9")
 * **10**
   ![HyperV Step 10](hyper-v-10.png "HyperV Step 10")
 * **11**
   ![HyperV Step 11](hyper-v-11.png "HyperV Step 11")
 * **12**
   ![HyperV Step 12](hyper-v-12.png "HyperV Step 12")
 * **13**
   ![HyperV Step 13](hyper-v-13.png "HyperV Step 13")
 * **14**
   ![HyperV Step 14](hyper-v-14.png "HyperV Step 14")

### Disable IPv6

### Deactivate firewall

### Install Docker

Official Windows Documentation: [Get started: Prep Windows for containers](https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=Windows-Server)

![Docker Setup](docker.png "Docker  Setup")

PowerShell
```
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force

Install-Package -Name docker -ProviderName DockerMsftProvider

Restart-Computer -Force

```
### Enable Remote Managment

```
winrm quickconfig
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
```


## Join Windows to OCP Cluster

```
ansible-playbook -i ${CLUSTER_CONFIG}/inventory.ini /windows-machine-config-bootstrapper/tools/ansible/tasks/wsu/main.yaml -vv

ansible win -i ${CLUSTER_CONFIG}/inventory.ini -m win_ping -v
```

## Resources

 * https://github.com/ovn-org/ovn-kubernetes/issues/683
 * https://docs.microsoft.com/de-de/virtualization/windowscontainers/kubernetes/common-problems
 * https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1
 * https://docs.microsoft.com/en-us/virtualization/windowscontainers/container-networking/architecture
 * https://docs.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/create-a-virtual-switch-for-hyper-v-virtual-machines
 * https://docs.google.com/presentation/d/1YofaUnlkBzFfeG9VIvzuBX5fC6C3w9M1bjTpbskw6RY/edit#slide=id.g7261e2d0f6_2_2732

