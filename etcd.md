# etcd

## etcd commands

## List keys

```text
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS='https://q:2379'
export ETCDCTL_CERT=/etc/etcd/peer.crt
export ETCDCTL_KEY=/etc/etcd/peer.key 
export ETCDCTL_CACERT=/etc/etcd/ca.crt

etcdctl version

etcdctl get / --prefix --keys-only
```

