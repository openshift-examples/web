---
title: Etcd Backup
linktitle: Etcd
description: Examples for etcd backups
tags:
  - backup
  - etcd
---

# ETCD Backup

Official documentation: https://docs.openshift.com/container-platform/latest/backup_and_restore/backing-up-etcd.html


## With ACM

https://github.com/open-cluster-management/policy-collection/blob/master/community/CM-Configuration-Management/policy-etcd-backup.yaml

## Try to run in a Pod 

 * Create pvc with name `etcd-backup`

!!! note
    Inline bash to get the etcd image, etcd image will change after a cluster upgrade.

    Skip podman and umount, because only needed to extract etcd client from image.



```yaml
oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: etcd-backup
  name: etcd-backup
spec:
  nodeSelector:
    node-role.kubernetes.io/master: ''
  containers:
  - command:
    - /bin/sh
    - -c
    - |
      function umount() { :; }
      export -f umount
      function podman() { :; }
      export -f podman

      /host/usr/local/bin/cluster-backup.sh /etcd-backup/
     
    image: $(oc get pod -n openshift-etcd -l app=etcd -o jsonpath="{.items[0].spec.containers[0].image}")
    name: etcd-backup
    securityContext:
      privileged: true
      runAsUser: 0
    resources: {}
    volumeMounts:
      - name: etcd-backup
        mountPath: /etcd-backup
      - name: host
        mountPath: /host
      - name: host-etc-kubernetes
        mountPath: /etc/kubernetes
  volumes:
    - name: etcd-backup
      persistentVolumeClaim:
        claimName: etcd-backup
    - name: host
      hostPath:
        path: /
        type: Directory
    - name: host-etc-kubernetes
      hostPath:
        path: /etc/kubernetes
        type: Directory
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
EOF
```

**Output:**
```bash
$ oc logs etcd-backup
etcdctl version: 3.4.9
API version: 3.4
found latest kube-apiserver-pod: /etc/kubernetes/static-pod-resources/kube-apiserver-pod-9
found latest kube-controller-manager-pod: /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-4
found latest kube-scheduler-pod: /etc/kubernetes/static-pod-resources/kube-scheduler-pod-5
found latest etcd-pod: /etc/kubernetes/static-pod-resources/etcd-pod-3
{"level":"info","ts":1612345971.3303144,"caller":"snapshot/v3_snapshot.go:119","msg":"created temporary db file","path":"/etcd-backup//snapshot_2021-02-03_095251.db.part"}
{"level":"info","ts":"2021-02-03T09:52:51.340Z","caller":"clientv3/maintenance.go:200","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":1612345971.3406882,"caller":"snapshot/v3_snapshot.go:127","msg":"fetching snapshot","endpoint":"https://192.168.52.12:2379"}
{"level":"info","ts":"2021-02-03T09:52:52.975Z","caller":"clientv3/maintenance.go:208","msg":"completed snapshot read; closing"}
{"level":"info","ts":1612345973.1738656,"caller":"snapshot/v3_snapshot.go:142","msg":"fetched snapshot","endpoint":"https://192.168.52.12:2379","size":"108 MB","took":1.84332374}
{"level":"info","ts":1612345973.174559,"caller":"snapshot/v3_snapshot.go:152","msg":"saved","path":"/etcd-backup//snapshot_2021-02-03_095251.db"}
Snapshot saved at /etcd-backup//snapshot_2021-02-03_095251.db
snapshot db and kube resources are successfully saved to /etcd-backup/
```