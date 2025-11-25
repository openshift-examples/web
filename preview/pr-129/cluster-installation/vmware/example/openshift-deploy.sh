#!/usr/bin/env bash

# How to use the script: copy it and adjust what you have to adjust!
#   For example: ip adresses ;-)

set -euo pipefail
set -x

# Moved into ~/.basrc ;-)
# export GOVC_URL='vcenter'
# export GOVC_USERNAME='user'
# export GOVC_PASSWORD='pwd'
# export GOVC_INSECURE=1
# export GOVC_DATACENTER="DC"
# export GOVC_DATASTORE="datastore"

basedomain="lab.example.com"
clustername="rbohne"

nodes=(
    "bootstrap.${clustername}.${basedomain}"
    "master-0.${clustername}.${basedomain}"
    "master-1.${clustername}.${basedomain}"
    "master-2.${clustername}.${basedomain}"
    "worker-1.${clustername}.${basedomain}"
    "worker-2.${clustername}.${basedomain}"
    "worker-3.${clustername}.${basedomain}"
)

ignitions=(
    "$(pwd)/rbohne/bootstrap.ign.base64"
    "$(pwd)/rbohne/master.ign.base64"
    "$(pwd)/rbohne/master.ign.base64"
    "$(pwd)/rbohne/master.ign.base64"
    "$(pwd)/rbohne/worker.ign.base64"
    "$(pwd)/rbohne/worker.ign.base64"
    "$(pwd)/rbohne/worker.ign.base64"
);

ips=(
    "ip=192.168.100.152::192.168.100.148:255.255.255.0:bootstrap.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
    "ip=192.168.100.149::192.168.100.148:255.255.255.0:master-0.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
    "ip=192.168.100.150::192.168.100.148:255.255.255.0:master-1.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
    "ip=192.168.100.151::192.168.100.148:255.255.255.0:master-2.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
    "ip=192.168.100.153::192.168.100.148:255.255.255.0:worker-1.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
    "ip=192.168.100.154::192.168.100.148:255.255.255.0:worker-2.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
    "ip=192.168.100.155::192.168.100.148:255.255.255.0:worker-3.${clustername}.${basedomain}:ens192:none nameserver=192.168.100.148"
)

# function govc {
#     echo "Dummy function"
# }

# Setup vm's
for (( i=0; i< ${#nodes[@]} ; i++ )) ; do
    node=${nodes[$i]}
    ip=${ips[$i]}
    ignition=${ignitions[$i]}

    echo "Setup $node -> $ip";

    # If you want to setup mac adress
    # mac_adresse=${mac_adresses[$i]}
    # -net.address ${mac_adresse} \

    govc vm.clone -vm "/${GOVC_DATACENTER}/vm/${clustername}/rhcos-4.6.47"  \
      -annotation=$ignition \
      -c=4 \
      -m=16384 \
      -net 'DC-Provisioning' \
      -on=false \
      -folder=${clustername} \
      -ds="${GOVC_DATASTORE}" \
      $node

    govc vm.change -vm="/${GOVC_DATACENTER}/vm/${clustername}/$node" \
      -e="guestinfo.afterburn.initrd.network-kargs=$ip" \
      -e="guestinfo.ignition.config.data.encoding=base64" \
      -f="guestinfo.ignition.config.data=${ignition}"

done;

# Start vm's
for node in ${nodes[@]} ; do
    echo "# Start $node";
    govc vm.power -on=true $node
done;