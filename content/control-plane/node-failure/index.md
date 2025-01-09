---
title: Node failure test
linktitle: Node failure
description: Let's switch off some control plane nodes.
tags: ['etcd','control-plane','v4.17']
---

# Control plane node failure test

* Just some stupid tests with OpenShift 4.17
* **With [OCPSTRAT-539](https://issues.redhat.com/browse/OCPSTRAT-539) there will be a improvement of the process. Hopefully, land in 4.18!**

Useful etcd commands

* Member list

  ```shell
  etcdctl member list -w table
  ```

* Endpoint status

  ```shell
  etcdctl endpoint status --cluster -w table
  ```

* Endpoint health

  ```shell
  etcdctl endpoint health --cluster -w table
  ```

## Control plane overview

Date:

* UTC: `2025-01-08 13:51:23 +0000`
* CET: `2025-01-08 14:51:35 +0100`

|Node|IP|Mac|Leader|API VIP|
|---|---|---|---|---|
|cp-1 (0)|10.32.105.69|0E:C0:EF:20:69:45|⚪️|⚪️|
|cp-2 (1)|10.32.105.70|0E:C0:EF:20:69:46|✅|⚪️|
|cp-3 (2)|10.32.105.71|0E:C0:EF:20:69:47|⚪️|✅|

Test Workload

|Time|API<br/>(ping/https)|WebUI<br/>(ping/https)|App <br/>(ping/https)|VM<br/>(ping/https)|
|---|---|---|---|---|
|`2025-01-08 13:51:23 +0000`|🟢 🟢|🟢 🟢|🟢 🟢|🟢 🟢|

??? quote "etcdctl endpoint status --cluster -w table"

    ```bash
    sh-5.1#   etcdctl endpoint status --cluster -w table
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.70:2379 | 4fb023e0ba979504 |  3.5.14 |  133 MB |     false |      false |        21 |     803932 |             803932 |        |
    | https://10.32.105.69:2379 | 8f13951319793d10 |  3.5.14 |  132 MB |      true |      false |        21 |     803932 |             803932 |        |
    | https://10.32.105.71:2379 | ced393e846a090ee |  3.5.14 |  135 MB |     false |      false |        21 |     803932 |             803932 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ```

## One control plane node stopeed

Date CET: `2025-01-08 15:06:37 +0100`

```bash
isar # cdate; virtctl stop -n stormshift-ocp1-infra ocp1-cp-1
2025-01-08 15:06:37 +0100
VM ocp1-cp-2 was scheduled to stop
isar #
```

|Node|IP|Mac|Leader|API VIP|
|---|---|---|---|---|
|cp-1 (0)|10.32.105.69|0E:C0:EF:20:69:45|⚪️|⚪️|
|cp-2 (1)|10.32.105.70|0E:C0:EF:20:69:46|✅|✅|
|cp-3 (2)|10.32.105.71|0E:C0:EF:20:69:47|🔴|🔴|

Test Workload

|Time|API<br/>(ping/https)|WebUI<br/>(ping/https)|App <br/>(ping/https)|VM<br/>(ping/https)|
|---|---|---|---|---|
|`2025-01-08 13:51:23 +0000`|🟢 🟢|🟢 🟢|🟢 🟢|🟢 🟢|

??? quote "etcdctl endpoint status --cluster -w table"

    ```bash
    sh-5.1# etcdctl endpoint status --cluster -w table
    {"level":"warn","ts":"2025-01-08T14:09:50.533659Z","logger":"etcd-client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000354000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
    Failed to get the status of endpoint https://10.32.105.71:2379 (context deadline exceeded)
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.70:2379 | 4fb023e0ba979504 |  3.5.14 |  134 MB |     false |      false |        21 |     817949 |             817949 |        |
    | https://10.32.105.69:2379 | 8f13951319793d10 |  3.5.14 |  134 MB |      true |      false |        21 |     817949 |             817949 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    sh-5.1#
    ```

??? quote "etcdctl endpoint health  -w table"

    ```bash
    sh-5.1# etcdctl endpoint health --cluster -w table
    {"level":"warn","ts":"2025-01-08T14:11:01.430788Z","logger":"etcd-client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0003e0000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
    Error: failed to fetch endpoints from etcd cluster member list: context deadline exceeded
    sh-5.1# etcdctl endpoint health  -w table
    {"level":"warn","ts":"2025-01-08T14:11:19.330933Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000018000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
    +---------------------------+--------+--------------+---------------------------+
    |         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
    +---------------------------+--------+--------------+---------------------------+
    | https://10.32.105.70:2379 |   true | 1.086873919s |                           |
    | https://10.32.105.69:2379 |   true | 1.176393623s |                           |
    | https://10.32.105.71:2379 |  false | 5.002713425s | context deadline exceeded |
    +---------------------------+--------+--------------+---------------------------+
    Error: unhealthy cluster
    sh-5.1#
    ```

??? quote "oc get nodes (stormshift-ocp1)"

    ```bash
    stormshift-ocp1 # oc get nodes
    NAME            STATUS     ROLES                  AGE   VERSION
    ocp1-cp-1       Ready      control-plane,master   20h   v1.30.4
    ocp1-cp-2       Ready      control-plane,master   21h   v1.30.4
    ocp1-cp-3       NotReady   control-plane,master   21h   v1.30.4
    ocp1-worker-1   Ready      worker                 19h   v1.30.4
    ocp1-worker-2   Ready      worker                 18h   v1.30.4
    ocp1-worker-3   Ready      worker                 18h   v1.30.4
    stormshift-ocp1 #
    ```

## Two control plane nodes stopeed

Date CET: `2025-01-08 15:16:06 +0100`

```bash
isar # cdate; virtctl stop -n stormshift-ocp1-infra ocp1-cp-1
2025-01-08 15:16:06 +0100
VM ocp1-cp-1 was scheduled to stop
isar #
```

|Node|IP|Mac|Leader|API VIP|
|---|---|---|---|---|
|cp-1 (0)|10.32.105.69|0E:C0:EF:20:69:45|⚪️|⚪️|
|cp-2 (1)|10.32.105.70|0E:C0:EF:20:69:46|🔴|🔴|
|cp-3 (2)|10.32.105.71|0E:C0:EF:20:69:47|🔴|🔴|

Test Workload

|Time|API<br/>(ping/https)|WebUI<br/>(ping/https)|App <br/>(ping/https)|VM<br/>(ping/https)|
|---|---|---|---|---|
|`2025-01-08 13:51:23 +0000`|🟢 🔴|🟢 🟢*|🟢 🟢|🟢 🟢|

* OpenShift Web console is "available" but without API useless and not really available.
* Control plane is read-only == offline / not available
* Workload is still running as expected

??? quote "etcdctl endpoint status --cluster -w table"

    etcd pods are not available via API anymore!

    ```bash
    % ssh -l core -i ~/.ssh/coe-muc 10.32.105.69
    [core@ocp1-cp-1 ~]$ sudo su -
    [root@ocp1-cp-1 ~]# crictl ps --name "^etcd$"
    CONTAINER           IMAGE                                                              CREATED             STATE               NAME                ATTEMPT             POD ID              POD
    12b84d7a637bd       3e2541880f59e43ba27714033241c45e0be80f0950a8d6e2fe5cfe5df86a800a   21 hours ago        Running             etcd                0                   43d64c15c722f       etcd-ocp1-cp-1
    [root@ocp1-cp-1 ~]# crictl exec -ti 12b84d7a637bd bash
    [root@ocp1-cp-1 /]# etcdctl endpoint status -w table
    {"level":"warn","ts":"2025-01-08T14:24:29.584514Z","logger":"etcd-client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000028000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.70:2379: connect: no route to host\""}
    Failed to get the status of endpoint https://10.32.105.70:2379 (context deadline exceeded)
    {"level":"warn","ts":"2025-01-08T14:24:34.585233Z","logger":"etcd-client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000028000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
    Failed to get the status of endpoint https://10.32.105.71:2379 (context deadline exceeded)
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX |        ERRORS         |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
    | https://10.32.105.69:2379 | 8f13951319793d10 |  3.5.14 |  135 MB |     false |      false |        21 |     822965 |             822965 | etcdserver: no leader |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+-----------------------+
    ```

??? quote "etcdctl endpoint health  -w table"

    ```bash
    [root@ocp1-cp-1 /]# etcdctl endpoint health  -w table
    {"level":"warn","ts":"2025-01-08T14:25:14.567156Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc00037e000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = context deadline exceeded"}
    {"level":"warn","ts":"2025-01-08T14:25:14.567096Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000018000/10.32.105.70:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.70:2379: connect: no route to host\""}
    {"level":"warn","ts":"2025-01-08T14:25:14.567096Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0000de000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
    +---------------------------+--------+--------------+---------------------------+
    |         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
    +---------------------------+--------+--------------+---------------------------+
    | https://10.32.105.69:2379 |  false | 5.000376526s | context deadline exceeded |
    | https://10.32.105.70:2379 |  false | 5.000426348s | context deadline exceeded |
    | https://10.32.105.71:2379 |  false | 5.000456502s | context deadline exceeded |
    +---------------------------+--------+--------------+---------------------------+
    Error: unhealthy cluster
    [root@ocp1-cp-1 /]#
    ```

??? quote "oc get nodes (stormshift-ocp1)"

    ```bash
    stormshift-ocp1 # oc get nodes
    E0108 15:18:32.888771   15036 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": EOF - error from a previous attempt: read tcp 10.45.224.32:49580->10.32.105.64:6443: read: connection reset by peer
    E0108 15:18:43.957199   15036 memcache.go:265] couldn't get current server API group list: Get "https://api.ocp1.stormshift.coe.muc.redhat.com:6443/api?timeout=32s": EOF
    ```

## Start the recovery process

Documentation: [5.3.2. Restoring to a previous cluster state](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/backup_and_restore/control-plane-backup-and-restore#dr-restoring-cluster-state)

### Run etcd Backup

Documentation: [5.1.1. Backing up etcd data](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/backup_and_restore/control-plane-backup-and-restore#backing-up-etcd-data_backup-etcd)

You have to run the backup script wiht `--force` because API is not available.

??? quote "/usr/local/bin/cluster-backup.sh"

    ```bash
    [root@ocp1-cp-1 ~]# date +"%F %T %z"
    2025-01-08 14:31:59 +0000
    [root@ocp1-cp-1 ~]# /usr/local/bin/cluster-backup.sh /home/core/assets/backup
    Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
    Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
    Error from server (Timeout): the server was unable to return a response in the time allotted, but may still be processing the request (get clusteroperators.config.openshift.io kube-apiserver)
    Could not find the status of the kube-apiserver. Check if the API server is running. Pass the --force flag to skip checks.
    [root@ocp1-cp-1 ~]# date +"%F %T %z"
    2025-01-08 14:33:17 +0000
    [root@ocp1-cp-1 ~]# /usr/local/bin/cluster-backup.sh --force /home/core/assets/backup
    Certificate /etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt is missing. Checking in different directory
    Certificate /etc/kubernetes/static-pod-resources/etcd-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt found!
    found latest kube-apiserver: /etc/kubernetes/static-pod-resources/kube-apiserver-pod-12
    found latest kube-controller-manager: /etc/kubernetes/static-pod-resources/kube-controller-manager-pod-10
    found latest kube-scheduler: /etc/kubernetes/static-pod-resources/kube-scheduler-pod-9
    found latest etcd: /etc/kubernetes/static-pod-resources/etcd-pod-10
    d3051a7ced55db5947f809d531d6821f310f422ad19eca1c5f87c83cd553e0c2
    etcdctl version: 3.5.14
    API version: 3.5
    {"level":"info","ts":"2025-01-08T14:33:24.839593Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/home/core/assets/backup/snapshot_2025-01-08_143323__POSSIBLY_DIRTY__.db.part"}
    {"level":"info","ts":"2025-01-08T14:33:24.852422Z","logger":"client","caller":"v3@v3.5.14/maintenance.go:212","msg":"opened snapshot stream; downloading"}
    {"level":"info","ts":"2025-01-08T14:33:24.8525Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://10.32.105.69:2379"}
    {"level":"info","ts":"2025-01-08T14:33:26.493909Z","logger":"client","caller":"v3@v3.5.14/maintenance.go:220","msg":"completed snapshot read; closing"}
    {"level":"info","ts":"2025-01-08T14:33:26.990149Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://10.32.105.69:2379","size":"135 MB","took":"2 seconds ago"}
    {"level":"info","ts":"2025-01-08T14:33:26.990347Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"/home/core/assets/backup/snapshot_2025-01-08_143323__POSSIBLY_DIRTY__.db"}
    Snapshot saved at /home/core/assets/backup/snapshot_2025-01-08_143323__POSSIBLY_DIRTY__.db
    {"hash":2206292178,"revision":739064,"totalKey":15086,"totalSize":134733824}
    snapshot db and kube resources are successfully saved to /home/core/assets/backup
    [root@ocp1-cp-1 ~]#
    ```

### Continue

Important points:

* A healthy control plane host to use as the recovery host.

??? quote "Point 6. check keepalived"

    ```bash
    [root@ocp1-cp-1 ~]# date +"%F %T %z"
    2025-01-08 14:39:01 +0000
    [root@ocp1-cp-1 ~]# ip -o address | grep 10.32.105.64
    5: br-ex    inet 10.32.105.64/32 scope global vip\       valid_lft forever preferred_lft forever
    [root@ocp1-cp-1 ~]#
    ```

??? quote "Point 8. cluster-restore.sh"

    ```bash
    [root@ocp1-cp-1 ~]# date +"%F %T %z"
    2025-01-08 14:40:33 +0000
    [root@ocp1-cp-1 ~]# /usr/local/bin/cluster-restore.sh /home/core/assets/backup
    1d3f2a4ed0f1f076267b6a2d51962bdb80f252bd9878ce8236f3148ab9bb2d61
    etcdctl version: 3.5.14
    API version: 3.5
    {"hash":2206292178,"revision":739064,"totalKey":15086,"totalSize":134733824}
    ...stopping kube-apiserver-pod.yaml
    ...stopping kube-controller-manager-pod.yaml
    ...stopping kube-scheduler-pod.yaml
    Waiting for container kube-controller-manager to stop
    .complete
    Waiting for container kube-apiserver to stop
    ................................................................................................................................complete
    Waiting for container kube-scheduler to stop
    complete
    ...stopping etcd-pod.yaml
    Waiting for container etcd to stop
    .complete
    Waiting for container etcdctl to stop
    ............................complete
    Waiting for container etcd-metrics to stop
    complete
    Waiting for container etcd-readyz to stop
    complete
    Moving etcd data-dir /var/lib/etcd/member to /var/lib/etcd-backup
    starting restore-etcd static pod
    starting kube-apiserver-pod.yaml
    static-pod-resources/kube-apiserver-pod-12/kube-apiserver-pod.yaml
    starting kube-controller-manager-pod.yaml
    static-pod-resources/kube-controller-manager-pod-10/kube-controller-manager-pod.yaml
    starting kube-scheduler-pod.yaml
    static-pod-resources/kube-scheduler-pod-9/kube-scheduler-pod.yaml
    [root@ocp1-cp-1 ~]#
    ```

    Accordint to monitoring, API was online at `2025-01-08 15:44:01`

??? quote "oc get nodes (stormshift-ocp1)"

    ```bash
    stormshift-ocp1 # oc get nodes
    NAME            STATUS     ROLES                  AGE   VERSION
    ocp1-cp-1       Ready      control-plane,master   21h   v1.30.4
    ocp1-cp-2       NotReady   control-plane,master   21h   v1.30.4
    ocp1-cp-3       NotReady   control-plane,master   21h   v1.30.4
    ocp1-worker-1   Ready      worker                 19h   v1.30.4
    ocp1-worker-2   Ready      worker                 19h   v1.30.4
    ocp1-worker-3   Ready      worker                 19h   v1.30.4
    stormshift-ocp1 #
    ```

??? quote "etcdctl endpoint status..."

    ```bash
    sh-5.1# env | grep ETCDCTL
    ETCDCTL_ENDPOINTS=https://10.32.105.69:2379,https://10.32.105.70:2379,https://10.32.105.71:2379
    ETCDCTL_KEY=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.key
    ETCDCTL_API=3
    ETCDCTL_CACERT=/etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt
    ETCDCTL_CERT=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.crt
    sh-5.1#
    sh-5.1# etcdctl endpoint status  -w table
    {"level":"warn","ts":"2025-01-08T14:48:49.981146Z","logger":"etcd-client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000026000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.70:2379: connect: no route to host\""}
    Failed to get the status of endpoint https://10.32.105.70:2379 (context deadline exceeded)
    {"level":"warn","ts":"2025-01-08T14:48:54.982148Z","logger":"etcd-client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000026000/10.32.105.69:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
    Failed to get the status of endpoint https://10.32.105.71:2379 (context deadline exceeded)
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.69:2379 | 79a42a230e96be95 |  3.5.14 |  135 MB |      true |      false |         2 |       4179 |               4178 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    sh-5.1# etcdctl endpoint status --cluster -w table
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.69:2379 | 79a42a230e96be95 |  3.5.14 |  135 MB |      true |      false |         2 |       4143 |               4140 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    ```

??? quote "etcdctl endpoint health  -w table"

    ```bash
    sh-5.1# env | grep ETCDCTL
    ETCDCTL_ENDPOINTS=https://10.32.105.69:2379,https://10.32.105.70:2379,https://10.32.105.71:2379
    ETCDCTL_KEY=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.key
    ETCDCTL_API=3
    ETCDCTL_CACERT=/etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt
    ETCDCTL_CERT=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.crt
    sh-5.1# etcdctl endpoint health  -w table
    {"level":"warn","ts":"2025-01-08T14:51:18.829117Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000034000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
    {"level":"warn","ts":"2025-01-08T14:51:18.829126Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc0000be000/10.32.105.70:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.70:2379: connect: no route to host\""}
    +---------------------------+--------+--------------+---------------------------+
    |         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
    +---------------------------+--------+--------------+---------------------------+
    | https://10.32.105.69:2379 |   true |  16.183827ms |                           |
    | https://10.32.105.71:2379 |  false | 5.003399674s | context deadline exceeded |
    | https://10.32.105.70:2379 |  false | 5.003434863s | context deadline exceeded |
    +---------------------------+--------+--------------+---------------------------+
    Error: unhealthy cluster
    sh-5.1# etcdctl endpoint health --cluster -w table
    +---------------------------+--------+-------------+-------+
    |         ENDPOINT          | HEALTH |    TOOK     | ERROR |
    +---------------------------+--------+-------------+-------+
    | https://10.32.105.69:2379 |   true | 14.208768ms |       |
    +---------------------------+--------+-------------+-------+
    sh-5.1#
    ```

|Node|IP|Mac|Leader|API VIP|
|---|---|---|---|---|
|cp-1 (0)|10.32.105.69|0E:C0:EF:20:69:45|✅|✅|
|cp-2 (1)|10.32.105.70|0E:C0:EF:20:69:46|🔴|🔴|
|cp-3 (2)|10.32.105.71|0E:C0:EF:20:69:47|🔴|🔴|

Test Workload

|API<br/>(ping/https)|WebUI<br/>(ping/https)|App <br/>(ping/https)|VM<br/>(ping/https)|
|---|---|---|---|
|🟢 🟢|🟢 🟢|🟢 🟢|🟢 🟢|

Contiue with steps in docs (kubelet restart, ovn-kubernetes, csr,...)

## Add two new control plane nodes

|Node|IP|Mac|Leader|API VIP|
|---|---|---|---|---|
|cp-1 (0)|10.32.105.69|0E:C0:EF:20:69:45|✅|✅|
|cp-2 (1)|10.32.105.70|0E:C0:EF:20:69:46|🔴|🔴|
|cp-3 (2)|10.32.105.71|0E:C0:EF:20:69:47|🔴|🔴|
|cp-4 (4)|10.32.105.72|0E:C0:EF:20:69:48|🛠️|🛠️|
|cp-5 (5)|10.32.105.73|0E:C0:EF:20:69:49|🛠️|🛠️|

|API<br/>(ping/https)|WebUI<br/>(ping/https)|App <br/>(ping/https)|VM<br/>(ping/https)|
|---|---|---|---|
|🟢 🟢|🟢 🟢|🟢 🟢|🟢 🟢|

* We basically follow the steps: [Cluster lifecycle -> Add node](cluster-lifecycle/add-node/)
* ✅ DNS (A / PTR) done
* ✅ DHCP done
* ✅ RHCOS Live ISO Uploaded (rhcos-417.94.202410090854-0-live.x86_64.iso)
* ✅ control plane igntion exported and available at `http://10.32.96.31/stormshift-ocp1-cp.ign`

### Add cp-4

#### Virtual Machine at ISAR / Hosting Cluster

=== "oc apply..."

    ```bash
    isar # oc apply -n stormshift-ocp1-infra -f ocp1-cp-4-vm.yaml
    virtualmachine.kubevirt.io/ocp1-cp-4 created
    ```

=== "ocp1-cp-4-vm.yaml"

    ```yaml
    --8<-- "content/control-plane/node-failure/ocp1-cp-4-vm.yaml"
    ```

Connect to console an run:

```bash
curl -L -O http://10.32.96.31/stormshift-ocp1-cp.ign
sudo coreos-installer install -i stormshift-ocp1-cp.ign /dev/vda
sudo reboot
```

Approve CSR at `stormshift-ocp1`

```bash
oc get csr | awk '/Pending/ { print $1 }' | xargs oc adm certificate approve
```

??? quote "oc get nodes (stormshift-ocp1)"

    ```bash
    stormshift-ocp1 # oc get nodes
    NAME            STATUS     ROLES                  AGE     VERSION
    ocp1-cp-1       Ready      control-plane,master   22h     v1.30.4
    ocp1-cp-2       NotReady   control-plane,master   22h     v1.30.4
    ocp1-cp-3       NotReady   control-plane,master   22h     v1.30.4
    ocp1-cp-4       Ready      control-plane,master   9m10s   v1.30.4
    ocp1-worker-1   Ready      worker                 20h     v1.30.4
    ocp1-worker-2   Ready      worker                 20h     v1.30.4
    ocp1-worker-3   Ready      worker                 20h     v1.30.4
    stormshift-ocp1 #
    ```

#### BareMetalHost (BMH)

=== "oc apply..."

    ```bash
    stormshift-ocp1 # oc apply -f ocp1-cp-4-bmh.yaml
    baremetalhost.metal3.io/ocp1-cp-4 created
    ```

=== "ocp1-cp-4-bmh.yaml"

    ```yaml
    --8<-- "content/control-plane/node-failure/ocp1-cp-4-bmh.yaml"
    ```

??? quote "oc get bmh -n openshift-machine-api"

    ```bash
    stormshift-ocp1 # oc get bmh -n openshift-machine-api
    NAME            STATE       CONSUMER                    ONLINE   ERROR   AGE
    ocp1-cp-1       unmanaged   ocp1-g6vbv-master-0         true             22h
    ocp1-cp-2       unmanaged   ocp1-g6vbv-master-1         true             22h
    ocp1-cp-3       unmanaged   ocp1-g6vbv-master-2         true             22h
    ocp1-cp-4       unmanaged   ocp1-cp-4                   true             54s
    ocp1-worker-1   unmanaged   ocp1-g6vbv-worker-0-jmj97   true             22h
    ocp1-worker-2   unmanaged   ocp1-g6vbv-worker-0-wnbqv   true             22h
    ocp1-worker-3   unmanaged   ocp1-g6vbv-worker-0-zszgr   true             22h
    stormshift-ocp1 #
    ```

#### Machine

=== "oc apply..."

    ```
    stormshift-ocp1 # oc apply -f ocp1-cp-4-machine.yaml
    machine.machine.openshift.io/ocp1-cp-4 created
    ```

=== "ocp1-cp-4-machine.yaml"

    ```yaml
    --8<-- "content/control-plane/node-failure/ocp1-cp-4-machine.yaml"
    ```

??? quote "oc get machine -n openshift-machine-api"

    ```bash
    stormshift-ocp1 # oc get machine -n openshift-machine-api
    NAME                        PHASE         TYPE   REGION   ZONE   AGE
    ocp1-cp-4                   Provisioned                          2m29s
    ocp1-g6vbv-master-0         Running                              22h
    ocp1-g6vbv-master-1         Running                              22h
    ocp1-g6vbv-master-2         Running                              22h
    ocp1-g6vbv-worker-0-jmj97   Running                              22h
    ocp1-g6vbv-worker-0-wnbqv   Running                              22h
    ocp1-g6vbv-worker-0-zszgr   Running                              22h
    stormshift-ocp1 #
    ```

#### Link Machine & BareMetalHost

Open API proxy in on terminal

```shell
oc proxy
```

Patch object in another terminal

??? quote "Patch the status field of bmh object"

    ```shell
    export HOST_PROXY_API_PATH="http://127.0.0.1:8001/apis/metal3.io/v1alpha1/namespaces/openshift-machine-api/baremetalhosts"

    read -r -d '' host_patch << EOF
    {
    "status": {
        "hardware": {
        "nics": [
            {
            "ip": "10.32.105.72",
            "mac": "0E:C0:EF:20:69:48"
            }
        ]
        }
    }
    }
    EOF

    curl -vv \
        -X PATCH \
        "${HOST_PROXY_API_PATH}/ocp1-cp-4/status" \
        -H "Content-type: application/merge-patch+json" \
        -d "${host_patch}"
    ```

??? quote "oc get bmh,machine -n openshift-machine-api"

    ```bash
    stormshift-ocp1 # oc get bmh,machine -n openshift-machine-api
    NAME                                    STATE       CONSUMER                    ONLINE   ERROR   AGE
    baremetalhost.metal3.io/ocp1-cp-1       unmanaged   ocp1-g6vbv-master-0         true             22h
    baremetalhost.metal3.io/ocp1-cp-2       unmanaged   ocp1-g6vbv-master-1         true             22h
    baremetalhost.metal3.io/ocp1-cp-3       unmanaged   ocp1-g6vbv-master-2         true             22h
    baremetalhost.metal3.io/ocp1-cp-4       unmanaged   ocp1-cp-4                   true             10m
    baremetalhost.metal3.io/ocp1-worker-1   unmanaged   ocp1-g6vbv-worker-0-jmj97   true             22h
    baremetalhost.metal3.io/ocp1-worker-2   unmanaged   ocp1-g6vbv-worker-0-wnbqv   true             22h
    baremetalhost.metal3.io/ocp1-worker-3   unmanaged   ocp1-g6vbv-worker-0-zszgr   true             22h

    NAME                                                     PHASE         TYPE   REGION   ZONE   AGE
    machine.machine.openshift.io/ocp1-cp-4                   Running                              10m
    machine.machine.openshift.io/ocp1-g6vbv-master-0         Running                              22h
    machine.machine.openshift.io/ocp1-g6vbv-master-1         Running                              22h
    machine.machine.openshift.io/ocp1-g6vbv-master-2         Running                              22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-jmj97   Running                              22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-wnbqv   Running                              22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-zszgr   Running                              22h
    stormshift-ocp1 #
    ```

#### Validate etcd

??? quote "etcdctl..."

    ```bash
    oc rsh etcd-ocp1-cp-1
    sh-5.1# etcdctl endpoint health  -w table
    {"level":"warn","ts":"2025-01-08T15:28:51.780019Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000340000/10.32.105.71:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.71:2379: connect: no route to host\""}
    {"level":"warn","ts":"2025-01-08T15:28:51.780366Z","logger":"client","caller":"v3@v3.5.14/retry_interceptor.go:63","msg":"retrying of unary invoker failed","target":"etcd-endpoints://0xc000194000/10.32.105.70:2379","attempt":0,"error":"rpc error: code = DeadlineExceeded desc = latest balancer error: last connection error: connection error: desc = \"transport: Error while dialing: dial tcp 10.32.105.70:2379: connect: no route to host\""}
    +---------------------------+--------+--------------+---------------------------+
    |         ENDPOINT          | HEALTH |     TOOK     |           ERROR           |
    +---------------------------+--------+--------------+---------------------------+
    | https://10.32.105.69:2379 |   true |  14.545613ms |                           |
    | https://10.32.105.71:2379 |  false | 5.001124017s | context deadline exceeded |
    | https://10.32.105.70:2379 |  false | 5.001175568s | context deadline exceeded |
    +---------------------------+--------+--------------+---------------------------+
    Error: unhealthy cluster
    sh-5.1# etcdctl endpoint health --cluster -w table
    +---------------------------+--------+-------------+-------+
    |         ENDPOINT          | HEALTH |    TOOK     | ERROR |
    +---------------------------+--------+-------------+-------+
    | https://10.32.105.69:2379 |   true | 12.013929ms |       |
    | https://10.32.105.72:2379 |   true | 17.867394ms |       |
    +---------------------------+--------+-------------+-------+
    sh-5.1# etcdctl endpoint status --cluster -w table
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.72:2379 |  85cab4c209d910e |  3.5.14 |  139 MB |     false |      false |         2 |      30900 |              30900 |        |
    | https://10.32.105.69:2379 | 79a42a230e96be95 |  3.5.14 |  140 MB |      true |      false |         2 |      30900 |              30900 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    sh-5.1# etcdctl member list  -w table
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    |        ID        | STATUS  |   NAME    |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    |  85cab4c209d910e | started | ocp1-cp-4 | https://10.32.105.72:2380 | https://10.32.105.72:2379 |      false |
    | 79a42a230e96be95 | started | ocp1-cp-1 | https://10.32.105.69:2380 | https://10.32.105.69:2379 |      false |
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    sh-5.1#
    sh-5.1# env |grep ETCDCTL
    ETCDCTL_ENDPOINTS=https://10.32.105.69:2379,https://10.32.105.70:2379,https://10.32.105.71:2379
    ETCDCTL_KEY=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.key
    ETCDCTL_API=3
    ETCDCTL_CACERT=/etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt
    ETCDCTL_CERT=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.crt
    ```

??? quote "oc get pods -n openshift-etcd -o wide"

    ```bash
    stormshift-ocp1 # oc get pods -n openshift-etcd -o wide
    NAME                           READY   STATUS      RESTARTS   AGE     IP             NODE        NOMINATED NODE   READINESS GATES
    etcd-guard-ocp1-cp-1           0/1     Running     0          22h     10.130.0.15    ocp1-cp-1   <none>           <none>
    etcd-guard-ocp1-cp-2           1/1     Running     0          22h     10.128.0.17    ocp1-cp-2   <none>           <none>
    etcd-guard-ocp1-cp-3           1/1     Running     0          22h     10.129.0.54    ocp1-cp-3   <none>           <none>
    etcd-guard-ocp1-cp-4           1/1     Running     0          9m4s    10.130.2.24    ocp1-cp-4   <none>           <none>
    etcd-ocp1-cp-1                 1/1     Running     0          48m     10.32.105.69   ocp1-cp-1   <none>           <none>
    etcd-ocp1-cp-2                 4/4     Running     0          22h     10.32.105.70   ocp1-cp-2   <none>           <none>
    etcd-ocp1-cp-3                 4/4     Running     0          21h     10.32.105.71   ocp1-cp-3   <none>           <none>
    etcd-ocp1-cp-4                 4/4     Running     0          9m9s    10.32.105.72   ocp1-cp-4   <none>           <none>
    installer-10-ocp1-cp-1         0/1     Completed   0          21h     <none>         ocp1-cp-1   <none>           <none>
    installer-10-ocp1-cp-2         0/1     Completed   0          22h     <none>         ocp1-cp-2   <none>           <none>
    installer-10-ocp1-cp-3         0/1     Completed   0          21h     <none>         ocp1-cp-3   <none>           <none>
    installer-12-ocp1-cp-4         0/1     Completed   0          13m     10.130.2.3     ocp1-cp-4   <none>           <none>
    installer-14-ocp1-cp-2         0/1     Pending     0          8m8s    <none>         ocp1-cp-2   <none>           <none>
    installer-7-ocp1-cp-1          0/1     Completed   0          22h     <none>         ocp1-cp-1   <none>           <none>
    installer-9-ocp1-cp-1          0/1     Completed   0          22h     <none>         ocp1-cp-1   <none>           <none>
    installer-9-ocp1-cp-2          0/1     Completed   0          22h     <none>         ocp1-cp-2   <none>           <none>
    installer-9-ocp1-cp-3          0/1     Completed   0          22h     <none>         ocp1-cp-3   <none>           <none>
    revision-pruner-10-ocp1-cp-1   0/1     Completed   0          22h     <none>         ocp1-cp-1   <none>           <none>
    revision-pruner-10-ocp1-cp-2   0/1     Completed   0          22h     <none>         ocp1-cp-2   <none>           <none>
    revision-pruner-10-ocp1-cp-3   0/1     Completed   0          22h     <none>         ocp1-cp-3   <none>           <none>
    revision-pruner-10-ocp1-cp-4   0/1     Completed   0          14m     10.130.2.6     ocp1-cp-4   <none>           <none>
    revision-pruner-11-ocp1-cp-1   0/1     Completed   0          14m     <none>         ocp1-cp-1   <none>           <none>
    revision-pruner-11-ocp1-cp-2   0/1     Pending     0          14m     <none>         ocp1-cp-2   <none>           <none>
    revision-pruner-11-ocp1-cp-3   0/1     Pending     0          14m     <none>         ocp1-cp-3   <none>           <none>
    revision-pruner-11-ocp1-cp-4   0/1     Completed   0          14m     10.130.2.11    ocp1-cp-4   <none>           <none>
    revision-pruner-12-ocp1-cp-1   0/1     Completed   0          13m     <none>         ocp1-cp-1   <none>           <none>
    revision-pruner-12-ocp1-cp-2   0/1     Pending     0          14m     <none>         ocp1-cp-2   <none>           <none>
    revision-pruner-12-ocp1-cp-3   0/1     Pending     0          13m     <none>         ocp1-cp-3   <none>           <none>
    revision-pruner-12-ocp1-cp-4   0/1     Completed   0          13m     10.130.2.13    ocp1-cp-4   <none>           <none>
    revision-pruner-13-ocp1-cp-1   0/1     Completed   0          8m15s   <none>         ocp1-cp-1   <none>           <none>
    revision-pruner-13-ocp1-cp-2   0/1     Pending     0          8m23s   <none>         ocp1-cp-2   <none>           <none>
    revision-pruner-13-ocp1-cp-3   0/1     Pending     0          8m19s   <none>         ocp1-cp-3   <none>           <none>
    revision-pruner-13-ocp1-cp-4   0/1     Completed   0          8m12s   10.130.2.27    ocp1-cp-4   <none>           <none>
    revision-pruner-14-ocp1-cp-1   0/1     Completed   0          8m5s    <none>         ocp1-cp-1   <none>           <none>
    revision-pruner-14-ocp1-cp-2   0/1     Pending     0          8m9s    <none>         ocp1-cp-2   <none>           <none>
    revision-pruner-14-ocp1-cp-3   0/1     Pending     0          8m7s    <none>         ocp1-cp-3   <none>           <none>
    revision-pruner-14-ocp1-cp-4   0/1     Completed   0          8m3s    10.130.2.28    ocp1-cp-4   <none>           <none>
    revision-pruner-9-ocp1-cp-1    0/1     Completed   0          22h     <none>         ocp1-cp-1   <none>           <none>
    revision-pruner-9-ocp1-cp-2    0/1     Completed   0          22h     <none>         ocp1-cp-2   <none>           <none>
    revision-pruner-9-ocp1-cp-3    0/1     Completed   0          22h     <none>         ocp1-cp-3   <none>           <none>
    stormshift-ocp1 #
    ```

Let's delete the old control-plane artifacts

#### Delete two old control plane artifacts

* Date: `2025-01-08 16:37:12 +0100`

???+ tip

    During this process, the API is not availale from time to time. Because of reconfiguration of etcd.
    I would recommend to do the cleanup at the end. After the recovery of all control plane nodes.

```bash
stormshift-ocp1 # oc delete node/ocp1-cp-2 node/ocp1-cp-3
node "ocp1-cp-2" deleted
node "ocp1-cp-3" deleted
stormshift-ocp1 #
```

??? quote "oc get -n openshift-machine-api bmh,machine"

    ```bash
    stormshift-ocp1 # oc get -n openshift-machine-api bmh,machine
    NAME                                    STATE       CONSUMER                    ONLINE   ERROR   AGE
    baremetalhost.metal3.io/ocp1-cp-1       unmanaged   ocp1-g6vbv-master-0         true             22h
    baremetalhost.metal3.io/ocp1-cp-4       unmanaged   ocp1-cp-4                   true             30m
    baremetalhost.metal3.io/ocp1-worker-1   unmanaged   ocp1-g6vbv-worker-0-jmj97   true             22h
    baremetalhost.metal3.io/ocp1-worker-2   unmanaged   ocp1-g6vbv-worker-0-wnbqv   true             22h
    baremetalhost.metal3.io/ocp1-worker-3   unmanaged   ocp1-g6vbv-worker-0-zszgr   true             22h

    NAME                                                     PHASE     TYPE   REGION   ZONE   AGE
    machine.machine.openshift.io/ocp1-cp-4                   Running                          30m
    machine.machine.openshift.io/ocp1-g6vbv-master-0         Running                          22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-jmj97   Running                          22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-wnbqv   Running                          22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-zszgr   Running                          22h
    stormshift-ocp1 #
    ```

??? quote "oc get pods -n openshift-etcd"

    ```bash
    stormshift-ocp1 # oc get pods -n openshift-etcd
    NAME                           READY   STATUS      RESTARTS   AGE
    etcd-guard-ocp1-cp-1           1/1     Running     0          22h
    etcd-guard-ocp1-cp-4           1/1     Running     0          13m
    etcd-ocp1-cp-1                 4/4     Running     0          23s
    etcd-ocp1-cp-4                 4/4     Running     0          13m
    installer-10-ocp1-cp-1         0/1     Completed   0          22h
    installer-12-ocp1-cp-4         0/1     Completed   0          18m
    installer-15-ocp1-cp-1         0/1     Completed   0          2m43s
    installer-15-ocp1-cp-4         1/1     Running     0          9s
    installer-9-ocp1-cp-1          0/1     Completed   0          22h
    revision-pruner-10-ocp1-cp-1   0/1     Completed   0          22h
    revision-pruner-10-ocp1-cp-4   0/1     Completed   0          19m
    revision-pruner-11-ocp1-cp-1   0/1     Completed   0          18m
    revision-pruner-11-ocp1-cp-4   0/1     Completed   0          18m
    revision-pruner-12-ocp1-cp-1   0/1     Completed   0          18m
    revision-pruner-12-ocp1-cp-4   0/1     Completed   0          18m
    revision-pruner-13-ocp1-cp-1   0/1     Completed   0          12m
    revision-pruner-13-ocp1-cp-4   0/1     Completed   0          12m
    revision-pruner-14-ocp1-cp-1   0/1     Completed   0          12m
    revision-pruner-14-ocp1-cp-4   0/1     Completed   0          12m
    revision-pruner-15-ocp1-cp-1   0/1     Completed   0          2m44s
    revision-pruner-15-ocp1-cp-4   0/1     Completed   0          2m41s
    revision-pruner-9-ocp1-cp-1    0/1     Completed   0          22h
    ```

??? quote "etcdctl..."

    ```bash
    oc rsh etcd-ocp1-cp-1
    sh-5.1# etcdctl endpoint health  -w table
    +---------------------------+--------+-------------+-------+
    |         ENDPOINT          | HEALTH |    TOOK     | ERROR |
    +---------------------------+--------+-------------+-------+
    | https://10.32.105.72:2379 |   true | 17.002588ms |       |
    | https://10.32.105.69:2379 |   true |  23.96274ms |       |
    +---------------------------+--------+-------------+-------+
    sh-5.1# etcdctl endpoint health --cluster -w table
    +---------------------------+--------+-------------+-------+
    |         ENDPOINT          | HEALTH |    TOOK     | ERROR |
    +---------------------------+--------+-------------+-------+
    | https://10.32.105.69:2379 |   true | 11.619398ms |       |
    | https://10.32.105.72:2379 |   true | 16.879731ms |       |
    +---------------------------+--------+-------------+-------+
    sh-5.1# etcdctl endpoint status --cluster -w table
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.72:2379 |  85cab4c209d910e |  3.5.14 |  145 MB |     false |      false |         7 |      40236 |              40236 |        |
    | https://10.32.105.69:2379 | 79a42a230e96be95 |  3.5.14 |  145 MB |      true |      false |         7 |      40236 |              40236 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    sh-5.1# etcdctl endpoint status  -w table
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.69:2379 | 79a42a230e96be95 |  3.5.14 |  145 MB |      true |      false |         7 |      40264 |              40264 |        |
    | https://10.32.105.72:2379 |  85cab4c209d910e |  3.5.14 |  145 MB |     false |      false |         7 |      40264 |              40264 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    sh-5.1# etcdctl member list  -w table
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    |        ID        | STATUS  |   NAME    |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    |  85cab4c209d910e | started | ocp1-cp-4 | https://10.32.105.72:2380 | https://10.32.105.72:2379 |      false |
    | 79a42a230e96be95 | started | ocp1-cp-1 | https://10.32.105.69:2380 | https://10.32.105.69:2379 |      false |
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    sh-5.1# env | grep ETCDCTL
    ETCDCTL_ENDPOINTS=https://10.32.105.69:2379,https://10.32.105.72:2379
    ETCDCTL_KEY=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.key
    ETCDCTL_API=3
    ETCDCTL_CACERT=/etc/kubernetes/static-pod-certs/configmaps/etcd-all-bundles/server-ca-bundle.crt
    ETCDCTL_CERT=/etc/kubernetes/static-pod-certs/secrets/etcd-all-certs/etcd-peer-ocp1-cp-1.crt
    sh-5.1#
    ```

???+ warning "Cluster alert:"

    **NoOvnClusterManagerLeader**

    > Networking control plane is degraded. Networking configuration updates applied to the cluster will not be implemented while there is no OVN Kubernetes cluster manager leader. Existing workloads should continue to have connectivity. OVN-Kubernetes control plane is not functional.

    Let's handle that later, first recovery the whole control plane!

### Add cp-5

#### Virtual Machine at ISAR / Hosting Cluster (cp-5)

=== "oc apply..."

    ```bash
    isar # oc apply -n stormshift-ocp1-infra -f ocp1-cp-5-vm.yaml
    virtualmachine.kubevirt.io/ocp1-cp-5 created
    ```

=== "ocp1-cp-5-vm.yaml"

    ```yaml
    --8<-- "content/control-plane/node-failure/ocp1-cp-5-vm.yaml"
    ```

Connect to console an run:

```bash
curl -L -O http://10.32.96.31/stormshift-ocp1-cp.ign
sudo coreos-installer install -i stormshift-ocp1-cp.ign /dev/vda
sudo reboot
```

Approve CSR at `stormshift-ocp1`

```bash
oc get csr | awk '/Pending/ { print $1 }' | xargs oc adm certificate approve
```

??? quote "oc get nodes (stormshift-ocp1)"

    ```bash
    stormshift-ocp1 # oc get nodes
    NAME            STATUS     ROLES                  AGE     VERSION
    ocp1-cp-1       Ready      control-plane,master   22h     v1.30.4
    ocp1-cp-2       NotReady   control-plane,master   22h     v1.30.4
    ocp1-cp-3       NotReady   control-plane,master   22h     v1.30.4
    ocp1-cp-5       Ready      control-plane,master   9m10s   v1.30.4
    ocp1-worker-1   Ready      worker                 20h     v1.30.4
    ocp1-worker-2   Ready      worker                 20h     v1.30.4
    ocp1-worker-3   Ready      worker                 20h     v1.30.4
    stormshift-ocp1 #
    ```

#### BareMetalHost (BMH) (cp-5)

=== "oc apply..."

    ```bash
    stormshift-ocp1 # oc apply -f ocp1-cp-5-bmh.yaml
    baremetalhost.metal3.io/ocp1-cp-5 created
    ```

=== "ocp1-cp-5-bmh.yaml"

    ```yaml
    --8<-- "content/control-plane/node-failure/ocp1-cp-5-bmh.yaml"
    ```

??? quote "oc get bmh -n openshift-machine-api"

    ```bash
    stormshift-ocp1 # oc get bmh -n openshift-machine-api
    NAME            STATE       CONSUMER                    ONLINE   ERROR   AGE
    ocp1-cp-1       unmanaged   ocp1-g6vbv-master-0         true             22h
    ocp1-cp-4       unmanaged   ocp1-cp-4                   true             45m
    ocp1-cp-5       unmanaged   ocp1-cp-5                   true             2m34s
    ocp1-worker-1   unmanaged   ocp1-g6vbv-worker-0-jmj97   true             22h
    ocp1-worker-2   unmanaged   ocp1-g6vbv-worker-0-wnbqv   true             22h
    ocp1-worker-3   unmanaged   ocp1-g6vbv-worker-0-zszgr   true             22h
    stormshift-ocp1 #
    ```

#### Machine (cp-5)

=== "oc apply..."

    ```
    stormshift-ocp1 # oc apply -f ocp1-cp-5-machine.yaml
    machine.machine.openshift.io/ocp1-cp-5 created
    ```

=== "ocp1-cp-5-machine.yaml"

    ```yaml
    --8<-- "content/control-plane/node-failure/ocp1-cp-5-machine.yaml"
    ```

??? quote "oc get machine -n openshift-machine-api"

    ```bash
    stormshift-ocp1 # oc get machine -n openshift-machine-api
    NAME                        PHASE         TYPE   REGION   ZONE   AGE
    ocp1-cp-4                   Running                              45m
    ocp1-cp-5                   Provisioned                          2m49s
    ocp1-g6vbv-master-0         Running                              22h
    ocp1-g6vbv-worker-0-jmj97   Running                              22h
    ocp1-g6vbv-worker-0-wnbqv   Running                              22h
    ocp1-g6vbv-worker-0-zszgr   Running                              22h
    stormshift-ocp1 #
    ```

#### Link Machine & BareMetalHost (cp-5)

Open API proxy in on terminal

```shell
oc proxy
```

Patch object in another terminal

??? quote "Patch the status field of bmh object"

    ```shell
    export HOST_PROXY_API_PATH="http://127.0.0.1:8001/apis/metal3.io/v1alpha1/namespaces/openshift-machine-api/baremetalhosts"

    read -r -d '' host_patch << EOF
    {
    "status": {
        "hardware": {
        "nics": [
            {
            "ip": "10.32.105.73",
            "mac": "0E:C0:EF:20:69:49"
            }
        ]
        }
    }
    }
    EOF

    curl -vv \
        -X PATCH \
        "${HOST_PROXY_API_PATH}/ocp1-cp-5/status" \
        -H "Content-type: application/merge-patch+json" \
        -d "${host_patch}"
    ```

??? quote "oc get bmh,machine -n openshift-machine-api"

    ```bash
    stormshift-ocp1 # oc get bmh,machine -n openshift-machine-api
    NAME                                    STATE       CONSUMER                    ONLINE   ERROR   AGE
    baremetalhost.metal3.io/ocp1-cp-1       unmanaged   ocp1-g6vbv-master-0         true             23h
    baremetalhost.metal3.io/ocp1-cp-4       unmanaged   ocp1-cp-4                   true             50m
    baremetalhost.metal3.io/ocp1-cp-5       unmanaged   ocp1-cp-5                   true             7m56s
    baremetalhost.metal3.io/ocp1-worker-1   unmanaged   ocp1-g6vbv-worker-0-jmj97   true             23h
    baremetalhost.metal3.io/ocp1-worker-2   unmanaged   ocp1-g6vbv-worker-0-wnbqv   true             23h
    baremetalhost.metal3.io/ocp1-worker-3   unmanaged   ocp1-g6vbv-worker-0-zszgr   true             23h

    NAME                                                     PHASE     TYPE   REGION   ZONE   AGE
    machine.machine.openshift.io/ocp1-cp-4                   Running                          50m
    machine.machine.openshift.io/ocp1-cp-5                   Running                          7m53s
    machine.machine.openshift.io/ocp1-g6vbv-master-0         Running                          23h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-jmj97   Running                          22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-wnbqv   Running                          22h
    machine.machine.openshift.io/ocp1-g6vbv-worker-0-zszgr   Running                          22h
    stormshift-ocp1 #
    ```

### Validate etcd again

??? quote "Check etcd rollout..."

    ```bash
    stormshift-ocp1 # oc get pods -n openshift-etcd
    NAME                           READY   STATUS              RESTARTS   AGE
    etcd-guard-ocp1-cp-1           1/1     Running             0          22h
    etcd-guard-ocp1-cp-4           1/1     Running             0          35m
    etcd-ocp1-cp-1                 4/4     Running             0          21m
    etcd-ocp1-cp-4                 4/4     Running             0          17m
    installer-12-ocp1-cp-4         0/1     Completed           0          40m
    installer-15-ocp1-cp-1         0/1     Completed           0          24m
    installer-15-ocp1-cp-4         0/1     Completed           0          21m
    installer-17-ocp1-cp-5         0/1     ContainerCreating   0          55s
    revision-pruner-11-ocp1-cp-1   0/1     Completed           0          40m
    revision-pruner-11-ocp1-cp-4   0/1     Completed           0          40m
    revision-pruner-12-ocp1-cp-1   0/1     Completed           0          39m
    revision-pruner-12-ocp1-cp-4   0/1     Completed           0          39m
    revision-pruner-13-ocp1-cp-1   0/1     Completed           0          34m
    revision-pruner-13-ocp1-cp-4   0/1     Completed           0          34m
    revision-pruner-14-ocp1-cp-1   0/1     Completed           0          34m
    revision-pruner-14-ocp1-cp-4   0/1     Completed           0          34m
    revision-pruner-15-ocp1-cp-1   0/1     Completed           0          24m
    revision-pruner-15-ocp1-cp-4   0/1     Completed           0          24m
    revision-pruner-15-ocp1-cp-5   0/1     ContainerCreating   0          87s
    revision-pruner-16-ocp1-cp-1   0/1     Completed           0          73s
    revision-pruner-16-ocp1-cp-4   0/1     Completed           0          70s
    revision-pruner-16-ocp1-cp-5   0/1     ContainerCreating   0          66s
    revision-pruner-17-ocp1-cp-1   0/1     Completed           0          62s
    revision-pruner-17-ocp1-cp-4   0/1     Completed           0          59s
    revision-pruner-17-ocp1-cp-5   0/1     ContainerCreating   0          56s
    oc get pods
    NAME                           READY   STATUS      RESTARTS   AGE
    etcd-guard-ocp1-cp-1           1/1     Running     0          22h
    etcd-guard-ocp1-cp-4           1/1     Running     0          37m
    etcd-guard-ocp1-cp-5           1/1     Running     0          72s
    etcd-ocp1-cp-1                 4/4     Running     0          23m
    etcd-ocp1-cp-4                 4/4     Running     0          20m
    etcd-ocp1-cp-5                 4/4     Running     0          76s
    installer-12-ocp1-cp-4         0/1     Completed   0          42m
    installer-15-ocp1-cp-1         0/1     Completed   0          26m
    installer-15-ocp1-cp-4         0/1     Completed   0          23m
    installer-17-ocp1-cp-5         0/1     Completed   0          3m5s
    installer-19-ocp1-cp-1         1/1     Running     0          14s
    revision-pruner-11-ocp1-cp-1   0/1     Completed   0          42m
    revision-pruner-11-ocp1-cp-4   0/1     Completed   0          42m
    revision-pruner-12-ocp1-cp-1   0/1     Completed   0          42m
    revision-pruner-12-ocp1-cp-4   0/1     Completed   0          42m
    revision-pruner-13-ocp1-cp-1   0/1     Completed   0          36m
    revision-pruner-13-ocp1-cp-4   0/1     Completed   0          36m
    revision-pruner-14-ocp1-cp-1   0/1     Completed   0          36m
    revision-pruner-14-ocp1-cp-4   0/1     Completed   0          36m
    revision-pruner-15-ocp1-cp-1   0/1     Completed   0          26m
    revision-pruner-15-ocp1-cp-4   0/1     Completed   0          26m
    revision-pruner-15-ocp1-cp-5   0/1     Completed   0          3m37s
    revision-pruner-16-ocp1-cp-1   0/1     Completed   0          3m23s
    revision-pruner-16-ocp1-cp-4   0/1     Completed   0          3m20s
    revision-pruner-16-ocp1-cp-5   0/1     Completed   0          3m16s
    revision-pruner-17-ocp1-cp-1   0/1     Completed   0          3m12s
    revision-pruner-17-ocp1-cp-4   0/1     Completed   0          3m9s
    revision-pruner-17-ocp1-cp-5   0/1     Completed   0          3m6s
    revision-pruner-18-ocp1-cp-1   0/1     Completed   0          29s
    revision-pruner-18-ocp1-cp-4   0/1     Completed   0          26s
    revision-pruner-18-ocp1-cp-5   0/1     Completed   0          23s
    revision-pruner-19-ocp1-cp-1   0/1     Completed   0          20s
    revision-pruner-19-ocp1-cp-4   0/1     Completed   0          16s
    revision-pruner-19-ocp1-cp-5   0/1     Completed   0          14s
    stormshift-ocp1 # oc get co/etcd
    NAME   VERSION   AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
    etcd   4.17.0    True        True          True       22h     EtcdCertSignerControllerDegraded: EtcdCertSignerController can't evaluate whether quorum is safe: etcd cluster has quorum of 2 which is not fault tolerant: [{Member:ID:602544793613865230 name:"ocp1-cp-4" peerURLs:"https://10.32.105.72:2380" clientURLs:"https://10.32.105.72:2379"  Healthy:true Took:1.580703ms Error:<nil>} {Member:ID:8765177104826810005 name:"ocp1-cp-1" peerURLs:"https://10.32.105.69:2380" clientURLs:"https://10.32.105.69:2379"  Healthy:true Took:1.605857ms Error:<nil>}]

    ```

=> Wait until all etcd member are at revision 19

??? quote "etcdctl ..."

    ```bash
    sh-5.1# etcdctl endpoint health  -w table
    +---------------------------+--------+-------------+-------+
    |         ENDPOINT          | HEALTH |    TOOK     | ERROR |
    +---------------------------+--------+-------------+-------+
    | https://10.32.105.72:2379 |   true | 13.517796ms |       |
    | https://10.32.105.69:2379 |   true | 17.334331ms |       |
    | https://10.32.105.73:2379 |   true | 17.188206ms |       |
    +---------------------------+--------+-------------+-------+
    sh-5.1# etcdctl endpoint health --cluster -w table
    \+---------------------------+--------+-------------+-------+
    |         ENDPOINT          | HEALTH |    TOOK     | ERROR |
    +---------------------------+--------+-------------+-------+
    | https://10.32.105.73:2379 |   true | 13.722722ms |       |
    | https://10.32.105.69:2379 |   true |  15.68852ms |       |
    | https://10.32.105.72:2379 |   true | 18.331362ms |       |
    +---------------------------+--------+-------------+-------+
    sh-5.1#  etcdctl endpoint status --cluster -w table
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    |         ENDPOINT          |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    | https://10.32.105.72:2379 |  85cab4c209d910e |  3.5.14 |  153 MB |     false |      false |        10 |      59190 |              59190 |        |
    | https://10.32.105.69:2379 | 79a42a230e96be95 |  3.5.14 |  151 MB |      true |      false |        10 |      59190 |              59190 |        |
    | https://10.32.105.73:2379 | 86fab56c0f939612 |  3.5.14 |  150 MB |     false |      false |        10 |      59190 |              59190 |        |
    +---------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
    sh-5.1# etcdctl member list  -w table
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    |        ID        | STATUS  |   NAME    |        PEER ADDRS         |       CLIENT ADDRS        | IS LEARNER |
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    |  85cab4c209d910e | started | ocp1-cp-4 | https://10.32.105.72:2380 | https://10.32.105.72:2379 |      false |
    | 79a42a230e96be95 | started | ocp1-cp-1 | https://10.32.105.69:2380 | https://10.32.105.69:2379 |      false |
    | 86fab56c0f939612 | started | ocp1-cp-5 | https://10.32.105.73:2380 | https://10.32.105.73:2379 |      false |
    +------------------+---------+-----------+---------------------------+---------------------------+------------+
    sh-5.1#
    ```

## NoRunningOvnControlPlane

Still persist.

```bash
stormshift-ocp1 # oc -n openshift-ovn-kubernetes delete pod -l app=ovnkube-control-plane --wait=false
pod "ovnkube-control-plane-78c675bd69-vlx6k" deleted
pod "ovnkube-control-plane-78c675bd69-wt8dc" deleted
stormshift-ocp1 #
stormshift-ocp1 # oc -n openshift-ovn-kubernetes get pod -l app=ovnkube-control-plane

NAME                                     READY   STATUS             RESTARTS      AGE
ovnkube-control-plane-78c675bd69-cvcfm   2/2     Running            1 (37s ago)   39s
ovnkube-control-plane-78c675bd69-thp9d   1/2     CrashLoopBackOff   2 (20s ago)   39s

stormshift-ocp1 # oc -n openshift-ovn-kubernetes get pod -l app=ovnkube-control-plane -o wide
NAME                                     READY   STATUS             RESTARTS        AGE   IP             NODE        NOMINATED NODE   READINESS GATES
ovnkube-control-plane-78c675bd69-cvcfm   1/2     NotReady           10 (115s ago)   19m   10.32.105.73   ocp1-cp-5   <none>           <none>
ovnkube-control-plane-78c675bd69-thp9d   1/2     CrashLoopBackOff   12 (48s ago)    19m   10.32.105.72   ocp1-cp-4   <none>           <none>
stormshift-ocp1 #

```

Try to restart kubelet on ocp1-cp-5 and ocp1-cp-4, doesn't help. Let's reboot the nodes.

Restart of ocp1-cp-5 done, still CrashLoopBackOff.

Solution: [ovnkube-control-plane crashes on restart after adding an OVN-Kubernetes NAD for localnet topology](https://access.redhat.com/solutions/7095785)

??? quote "Fix ovnkube-control-plane crashes"

    ```bash
    stormshift-ocp1 # oc get net-attach-def -A
    NAMESPACE       NAME   AGE
    localnet-demo   coe    23h
    stormshift-ocp1 # oc get net-attach-def -n localnet-demo coe -o yaml | yq 'del(.metadata.creationTimestamp)| del(.metadata.generation)|del(.metadata.resourceVersion)|del(.metadata.uid)' > localnet-demo.yaml
    stormshift-ocp1 # oc delete  net-attach-def -n localnet-demo coe
    networkattachmentdefinition.k8s.cni.cncf.io "coe" deleted
    stormshift-ocp1 # oc -n openshift-ovn-kubernetes get pod -l app=ovnkube-control-plane -o wide
    NAME                                     READY   STATUS             RESTARTS          AGE   IP             NODE        NOMINATED NODE   READINESS GATES
    ovnkube-control-plane-78c675bd69-7v7qm   1/2     CrashLoopBackOff   210 (3m5s ago)    17h   10.32.105.69   ocp1-cp-1   <none>           <none>
    ovnkube-control-plane-78c675bd69-bzs6c   1/2     CrashLoopBackOff   210 (2m10s ago)   17h   10.32.105.73   ocp1-cp-5   <none>           <none>
    stormshift-ocp1 # oc -n openshift-ovn-kubernetes delete pod -l app=ovnkube-control-plane --wait=false
    pod "ovnkube-control-plane-78c675bd69-7v7qm" deleted
    pod "ovnkube-control-plane-78c675bd69-bzs6c" deleted
    stormshift-ocp1 # oc -n openshift-ovn-kubernetes get pod -l app=ovnkube-control-plane -o wide
    NAME                                     READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
    ovnkube-control-plane-78c675bd69-c5j7l   2/2     Running   0          14s   10.32.105.73   ocp1-cp-5   <none>           <none>
    ovnkube-control-plane-78c675bd69-qlwzn   2/2     Running   0          14s   10.32.105.72   ocp1-cp-4   <none>           <none>
    stormshift-ocp1 # oc create -f localnet-demo.yaml
    networkattachmentdefinition.k8s.cni.cncf.io/coe created
    stormshift-ocp1 #
    ```

    **Workload / VM was not available during the timeframe of delete net-attach-def!**
