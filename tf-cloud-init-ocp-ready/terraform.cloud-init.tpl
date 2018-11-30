#cloud-config

rh_subscription:
  username: '${rh_subscription_username}'
  password: '${rh_subscription_password}'
  auto-attach: False
  add-pool: [ '${rh_subscription_pool}' ]
  disable-repo: [ '*' ]
  enable-repo: [ 'rhel-7-server-extras-rpms', 'rhel-7-server-rpms', 'rhel-7-server-extras-rpms', 'rhel-7-server-ose-3.11-rpms', 'rhel-7-fast-datapath-rpms', 'rhel-7-server-ansible-2.6-rpms' ]

# set the locale
locale: en_US.UTF-8
 
# timezone: set the timezone for this instance
timezone: UTC

# Override ntp with chrony configuration on Ubuntu
ntp:
  enabled: true
  ntp_client: chrony  # Uses cloud-init default chrony configuration

packages:
   - wget
   - git
   - net-tools
   - bind-utils
   - yum-utils
   - iptables-services
   - bridge-utils
   - bash-completion
   - kexec-tools
   - sos
   - psacct
   - docker-1.13.1

package_update: true

write_files:
  - path: /etc/sysconfig/docker-storage-setup
    permissions: 0644
    owner: root
    content: |
      DEVS=/dev/vdb
      VG=docker-vg

runcmd:
  - docker-storage-setup
  - systemctl enable docker
  - systemctl start docker
  - systemctl is-active docker

power_state:
  mode: reboot
