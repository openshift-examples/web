# inf48

## Enable sriov

 grubby --update-kernel=ALL --args="intel_iommu=on iommu=pt"

  cat /etc/modprobe.d/ixgbe.conf
   options ixgbe max_vfs=16
## hetzner-ocp4

```yaml
cluster_name: ocp-mgmt
public_domain: coe.muc.redhat.com

dns_provider: none
vm_autostart: true
letsencrypt_disabled: true
masters_schedulable: false
compute_count: 2
compute_vcpu: 8
compute_memory_size: 32768
compute_memory_unit: 'MiB'
# qemu-img image size specified.
#   You may use k, M, G, T, P or E suffixe
compute_root_disk_size: '120G'

ip_families:
  - IPv4
storage_nfs: true

image_pull_secret:


```


## Resources


 * https://www.linuxsecrets.com/476-how-to-enable-sr-iov-virtual-function-on-intel-ixgbe-nic
 * https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_monitoring_and_updating_the_kernel/configuring-kernel-command-line-parameters_managing-monitoring-and-updating-the-kernel
 * https://www.intel.com/content/www/us/en/developer/articles/technical/configure-sr-iov-network-virtual-functions-in-linux-kvm.html




qemu-img convert -f qcow2 -O raw my-qcow2.img /dev/sdb

lvcreate -n win10 -L 200G nvme
qemu-img convert -f qcow2 -O raw win10 /dev/nvme/win10
