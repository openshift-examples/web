---
description: Usefull etcd stuff
---

# ETCD

## Commands

### List keys

{% tabs %}
{% tab title="Env" %}
```text
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS='https://q:2379'
export ETCDCTL_CERT=/etc/etcd/peer.crt
export ETCDCTL_KEY=/etc/etcd/peer.key 
export ETCDCTL_CACERT=/etc/etcd/ca.crt

etcdctl version

etcdctl get / --prefix --keys-only
```
{% endtab %}

{% tab title="Paramter" %}
```
ETCDCTL_API=3 /usr/bin/etcdctl --cert /etc/etcd/peer.crt  --key /etc/etcd/peer.key --cacert  /etc/etcd/ca.crt get / --prefix --keys-only

```
{% endtab %}
{% endtabs %}

### Run etcdctl on containerised env

```text
export ETCDIMAGE=bastion.vmw.scc.internal:5000/rhel7/etcd:3.2.22 
alias etcdctl="docker run --net host -ti -v /var/lib/etcd/:/var/lib/etcd/:z -v /etc/etcd:/etc/etcd:z $ETCDIMAGE /usr/bin/etcdctl -cert-file /etc/etcd/peer.crt  --key-file /etc/etcd/peer.key --ca-file  /etc/etcd/ca.crt "
```

### Member commands

```text
member list
member status
cluster-health
```

### cURL commands

```text
alias curl="curl --cacert /etc/etcd/ca.crt --cert /etc/etcd/peer.crt   --key /etc/etcd/peer.key"

curl -s https://${ETCD_IP}:2379/v2/stats/self | python -m json.tool
curl -s https://${ETCD_IP}:2379/health | python -m json.tool

```

