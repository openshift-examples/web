# Windows Container auf VMware IPI

Doc Bugs:
  * <https://bugzilla.redhat.com/show_bug.cgi?id=1947052>
  * <https://bugzilla.redhat.com/show_bug.cgi?id=1943587>


**High level steps:**

1. Install OpenShift 4.7+ with `OVNKubernetes` SDN and `hybridOverlayConfig`
2. Prepare a Windows golden image <br/>
    Perfect time is during cluster installation ;-)

3. Expose DNS Record api-int... for Windows Machines


4. Install Windows Machine Config Operator (WMCO)
<!-- Creates the windows-user-data secret, important to MachineConfig to create node -->

5. Configure private key (public installed in golden image)
<!--

  Wihtout the secret propper secret, WMCO failed to start

  oc create secret generic cloud-private-key \
    --from-file=private-key.pem=$HOME/.ssh/windows-private-key.id_rsa \
    -n openshift-windows-machine-config-operator

-->

6. Create MachineSet



## Cluster installation

### Create install-config.yaml
```bash
openshift-install create install-config --dir=cluster
```

### Adjust install-config.yaml
```bash
cp -v cluster/install-config.yaml cluster/install-config-plain.yaml
sed -i 's/OpenShiftSDN/OVNKubernetes/' cluster/install-config.yaml
```
### Create manifests
```bash
openshift-install create manifests --dir=cluster/
```

### Configure hypride overlay

!!! note
    Import on vSphere is the `hybridOverlayVXLANPort` because of [Pod-to-pod connectivity between hosts is broken on my Kubernetes cluster running on vSphere](https://docs.microsoft.com/en-us/virtualization/windowscontainers/kubernetes/common-problems#pod-to-pod-connectivity-between-hosts-is-broken-on-my-kubernetes-cluster-running-on-vsphere)


```bash
cat >  cluster/manifests/cluster-network-03-config.yml << EOF
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  creationTimestamp: null
  name: cluster
spec:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  externalIP:
    policy: {}
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
  defaultNetwork:
    type: OVNKubernetes
    ovnKubernetesConfig:
      hybridOverlayConfig:
        hybridClusterNetwork:
        - cidr: 10.132.0.0/14
          hostPrefix: 23
        # Not supported with Windows 2019 LTSC
        hybridOverlayVXLANPort: 9898
status: {}
EOF
```

### Install cluster
```bash
openshift-install create cluster --dir=cluster/
```

## Prepare Windows golden image

Perfect time during OpenShift 4 installation :-)

### Get a Windows 1909 ISO & Install a VM

Maybe 2019 works too

!!!note
    * Windows Server 2019 => LTSC
    * Windows Server 1909 => SAC

### Update Windows

Remote Desktop

PS C:\Users\Administrator> Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
PS C:\Users\Administrator> Enable-NetFirewallRule -DisplayGroup "Remote Desktop"


GUI or CLI
```powershell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module PSWindowsUpdate
Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -Install -IgnoreReboot
```
Source: [win-updates.ps1](https://github.com/openshift/windows-machine-config-operator/blob/master/docs/vsphere_ci/scripts/win-updates.ps1)

### Disable IPv6

```powershell

> Get-NetAdapterBinding

> Disable-NetAdapterBinding -Name <Name> -ComponentID ms_tcpip6
```
### Install VMware Tools

Business as usual :-)

cmd: `d:\setup64 /s /v "/qb REBOOT=R"`

### Configure VMware Tools

```powershell
"exclude-nics=" | Set-Content -Path 'C:\ProgramData\VMware\VMware Tools\tools.conf'
```

### Install all Windows Updates



### Install OpenSSH

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

Set-Service -Name ssh-agent -StartupType 'Automatic'
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service ssh-agent
Start-Service sshd

$pubKeyConf = (Get-Content -path C:\ProgramData\ssh\sshd_config) -replace '#PubkeyAuthentication yes','PubkeyAuthentication yes'
$pubKeyConf | Set-Content -Path C:\ProgramData\ssh\sshd_config
$passwordConf = (Get-Content -path C:\ProgramData\ssh\sshd_config) -replace '#PasswordAuthentication yes','PasswordAuthentication yes'
$passwordConf | Set-Content -Path C:\ProgramData\ssh\sshd_config

Restart-Service sshd

```

### Setup Public Key

```powershell
"ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHHYQEdg8wxKijObWr4fM69/zaZv/ll7mR2ua0o2qxJMauiFMWpcD24Liihy20mOYCJEfGU3F+sAUeXL5vdSnxf21jt1bk04KAAKhLF0KlNN7eGVcG9cLR2+inugNIUIArVNNPKC4+bJkRmKS9XMByHDC20X82dTEETTtwS57au0GeuzeKK9tNOrZRABiBX3bTplyESx3KzSNoY9IhKYL58Z6RF7bus3dVtYWHpFw1FYl9E1eSnwKjN4fmAqILQe6CaJESoDRgMnOmMFFrDfgGHtw8tkhEera7iDI2ZBShccxaFLauCj5r8RtBS8NlvVJumVMsVooCHf6CVxCK0xFv17wbpW5+E8MNU9qkPVBznEed4jPyYbzEhmEHtXsgh75Y6Xp2Ycegxzl6Y1rxmSillki472kHZftihEWIGVyG3QW7vYdjemkJKDiYnqMYur6HgXEJc7L5h/rg1N7IDAOzRHGPmDbgj7QYkSPHL9CkpA/Y2CX48JtLVaLGywZO9X8= rbohne@stormshiftdeploy.coe.muc.redhat.com" | Set-Content -Path 'C:\ProgramData\ssh\administrators_authorized_keys'

# Fix permission
$acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

```

### Allow incoming connection for container logs:
```
$firewallRuleName = "ContainerLogsPort"
$containerLogsPort = "10250"
New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $containerLogsPort -EdgeTraversalPolicy Allow

```


### Install container runtime

```powershell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force
Restart-Computer -Force
```

### Pre pull images

TBD

### Optional: Clone VM

After sysprep you can not modifi the golden image anymore. I recommend to clone the VM and run the sysprep in the clone. If you want to change the golden image, you follow the process:
1) Made changes you want
2) Clone the VM
3) Run sysprep in the clone

### Sysprep to have a propper Template

#### Prepare unattend.xml

#### Run Sysprep tool
```
cd 'C:\Windows\System32\Sysprep\'
.\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Users\Administrator\unattend-1909.xml
```

## Resources & Links

* [How to Check your PowerShell Version](https://adamtheautomator.com/powershell-version/)
* [Windows Server-Wartungskanäle: LTSC und SAC](https://docs.microsoft.com/de-de/windows-server/get-started-19/servicing-channels-19)
* <https://docs.microsoft.com/de-de/virtualization/windowscontainers/manage-docker/configure-docker-daemon#clean-up-docker-data-and-system-components>
* [KMS-Clientsetupschlüssel](https://docs.microsoft.com/de-de/windows-server/get-started/kmsclientkeys)
* <https://docs.microsoft.com/de-de/windows-server/networking/sdn/technologies/hyper-v-network-virtualization/whats-new-hyperv-network-virtualization-windows-server>
* <https://www.software-express.de/info/windows-server2019-ltsc-sac/>
* <https://www.microsoft.com/de-de/evalcenter/evaluate-windows-server-2019>
* <https://docs.microsoft.com/en-us/windows/release-health/release-information>

### Windows SDN Debugging

* <https://github.com/microsoft/SDN/blob/master/Kubernetes/windows/debug/Debug.md>


### Windows 2019 - Failed

WMCO Pod:
```
2021-04-01T11:27:59.081Z	ERROR	controller-runtime.controller	Reconciler error	{"controller": "windowsmachine-controller", "request": "openshift-machine-api/win-hx4pn", "error": "failed to configure Windows VM 42037020-b6d0-1820-df2e-bb90efdaa952: configuring node network failed: error waiting for k8s.ovn.org/hybrid-overlay-distributed-router-gateway-mac node annotation for win-hx4pn: timeout waiting for k8s.ovn.org/hybrid-overlay-distributed-router-gateway-mac node annotation: timed out waiting for the condition", "errorVerbose": "timed out waiting for the condition\ntimeout waiting for k8s.ovn.org/hybrid-overlay-distributed-router-gateway-mac node annotation\ngithub.com/openshift/windows-machine-config-operator/pkg/controller/windowsmachine/nodeconfig.(*nodeConfig).waitForNodeAnnotation\n\t/remote-source/build/windows-machine-config-operator/pkg/controller/windowsmachine/nodeconfig/nodeconfig.go:264\ngithub.com/openshift/w
```

Missing VXLAN Port in networkdetailed created via `.\collectlogs.ps1 `


```
PS C:\Users\Administrator> Get-ComputerInfo | select WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer

WindowsProductName                      WindowsVersion OsHardwareAbstractionLayer
------------------                      -------------- --------------------------
Windows Server 2019 Standard Evaluation 1809           10.0.17763.737


PS C:\Users\Administrator> (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").BuildLabEx
17763.1.amd64fre.rs5_release.180914-1434

PS C:\Users\Administrator> $PSVersionTable.PSVersion

Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      17763  592

Nach Updates:

PS C:\Users\Administrator> Get-ComputerInfo | select WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer

WindowsProductName                      WindowsVersion OsHardwareAbstractionLayer
------------------                      -------------- --------------------------
Windows Server 2019 Standard Evaluation 1809           10.0.17763.1790


PS C:\Users\Administrator> Get-ComputerInfo | select WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer

WindowsProductName                      WindowsVersion OsHardwareAbstractionLayer
------------------                      -------------- --------------------------
Windows Server 2019 Standard Evaluation 1809           10.0.17763.1790


PS C:\Users\Administrator> $PSVersionTable.PSVersion

Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      17763  1490

--------



PS C:\Users\Administrator> Get-ComputerInfo | select WindowsProductName, WindowsVersion, OsHardwareAbstractionLayer

WindowsProductName                      WindowsVersion OsHardwareAbstractionLayer
------------------                      -------------- --------------------------
Windows Server 2019 Standard Evaluation 1809           10.0.17763.1852



PS C:\Users\Administrator> (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").BuildLabEx
17763.1.amd64fre.rs5_release.180914-1434
PS C:\Users\Administrator> $PSVersionTable.PSVersion

Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      17763  1852



```