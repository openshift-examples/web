# Connection problem with `kubevirt.io/allow-pod-bridge-network-live-migration` after live migration


## HCP Cluster sendling:

```bash
oc get nodes
NAME                      STATUS   ROLES    AGE   VERSION
sendling-d0c14274-6nbvl   Ready    worker   11d   v1.27.8+4fab27b
sendling-d0c14274-sz7rb   Ready    worker   11d   v1.27.8+4fab27b
```

<details>
  <summary>Ping check details node/sendling-d0c14274-6nbvl</summary>

```bash
oc debug node/sendling-d0c14274-6nbvl
Starting pod/sendling-d0c14274-6nbvl-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.128.8.133
If you don't see a command prompt, try pressing enter.
sh-4.4# ping www.google.de
PING www.google.de (172.253.62.94) 56(84) bytes of data.
64 bytes from bc-in-f94.1e100.net (172.253.62.94): icmp_seq=1 ttl=99 time=112 ms
64 bytes from bc-in-f94.1e100.net (172.253.62.94): icmp_seq=2 ttl=99 time=98.3 ms
^C
--- www.google.de ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1000ms
rtt min/avg/max/mdev = 98.310/105.047/111.785/6.745 ms
sh-4.4# exit
exit

Removing debug pod ...
```
</details>

<details>
  <summary>Ping check details node/sendling-d0c14274-sz7rb</summary>

```bash
$ oc debug node/sendling-d0c14274-sz7rb
Starting pod/sendling-d0c14274-sz7rb-debug ...
To use host binaries, run `chroot /host`
Pod IP: 10.131.9.28
If you don't see a command prompt, try pressing enter.
sh-4.4# ping www.google.de
PING www.google.de (172.253.62.94) 56(84) bytes of data.
```
</details>


* Node sendling-d0c14274-**6nbvl** - Ping google ✅
* Node sendling-d0c14274-**sz7rb** - Ping google ❌


```bash

$ oc get pods -l kubevirt.io=virt-launcher -o wide -n rbohne-hcp-sendling
NAME                                          READY   STATUS      RESTARTS   AGE     IP             NODE                 NOMINATED NODE   READINESS GATES
virt-launcher-sendling-d0c14274-6nbvl-pb6zd   1/1     Running     0          6d2h    10.128.8.133   inf8                 <none>           1/1
virt-launcher-sendling-d0c14274-sz7rb-cw5vj   1/1     Running     0          3d20h   10.131.9.28    ucs-blade-server-1   <none>           1/1
virt-launcher-sendling-d0c14274-sz7rb-mbmv8   0/1     Completed   0          3d20h   10.131.9.28    ucs-blade-server-3   <none>           1/1
virt-launcher-sendling-d0c14274-sz7rb-nb25r   0/1     Completed   0          6d2h    10.131.9.28    ucs-blade-server-1   <none>           1/1
$
```

### Checkout node routing:

Host subnets:
``` bash
$ oc get nodes -o custom-columns="NODE:.metadata.name,host-cidr:.metadata.annotations.k8s\.ovn\.org/host-cidrs,node-subnets:.
metadata.annotations.k8s\.ovn\.org/node-subnets"
NODE                 host-cidr                                           node-subnets
inf4                 ["10.32.96.4/20"]                                   {"default":["10.128.0.0/21"]}
inf44                ["10.32.96.44/20"]                                  {"default":["10.128.8.0/21"]}
inf5                 ["10.32.96.5/20","10.32.98.1/32","10.32.98.2/32"]   {"default":["10.130.0.0/21"]}
inf6                 ["10.32.96.6/20"]                                   {"default":["10.129.0.0/21"]}
inf7                 ["10.32.96.7/20"]                                   {"default":["10.128.16.0/21"]}
inf8                 ["10.32.96.8/20"]                                   {"default":["10.131.8.0/21"]}
ucs-blade-server-1   ["10.32.96.101/20"]                                 {"default":["10.131.0.0/21"]}
ucs-blade-server-3   ["10.32.96.103/20"]                                 {"default":["10.130.8.0/21"]}
...

$ oc get pods -n openshift-ovn-kubernetes -o wide -l  app=ovnkube-node
NAME                 READY   STATUS    RESTARTS       AGE    IP             NODE                 NOMINATED NODE   READINESS GATES
...
ovnkube-node-9xt5n   8/8     Running   8              2d7h   10.32.96.101   ucs-blade-server-1   <none>           <none>
ovnkube-node-hhsx5   8/8     Running   8              2d7h   10.32.96.8     inf8                 <none>           <none>
ovnkube-node-qx9bh   8/8     Running   9 (2d6h ago)   2d7h   10.32.96.103   ucs-blade-server-3   <none>           <none>
...

$ oc exec -n openshift-ovn-kubernetes -c ovn-controller ovnkube-node-9xt5n -- ovn-nbctl lr-route-list ovn_cluster_router
IPv4 Routes
Route Table <main>:
             10.128.8.133                100.88.0.9 dst-ip
             10.129.8.107              10.129.8.107 dst-ip rtos-ucs-blade-server-1 ecmp
             10.129.8.107                100.88.0.8 dst-ip ecmp
             10.130.10.29              10.130.10.29 dst-ip rtos-ucs-blade-server-1
              10.131.8.41               10.131.8.41 dst-ip rtos-ucs-blade-server-1
              10.131.9.28               10.131.9.28 dst-ip rtos-ucs-blade-server-1 ecmp
              10.131.9.28                100.88.0.8 dst-ip ecmp
              10.131.9.44               10.131.9.44 dst-ip rtos-ucs-blade-server-1
               100.64.0.2                100.88.0.2 dst-ip
               100.64.0.3                100.88.0.3 dst-ip
               100.64.0.4                100.88.0.4 dst-ip
               100.64.0.5                100.64.0.5 dst-ip
               100.64.0.6                100.88.0.6 dst-ip
               100.64.0.8                100.88.0.8 dst-ip
               100.64.0.9                100.88.0.9 dst-ip
              100.64.0.10               100.88.0.10 dst-ip
            10.128.0.0/21                100.88.0.2 dst-ip
            10.128.8.0/21                100.88.0.6 dst-ip
           10.128.16.0/21               100.88.0.10 dst-ip
            10.129.0.0/21                100.88.0.3 dst-ip
            10.130.0.0/21                100.88.0.4 dst-ip
            10.130.8.0/21                100.88.0.8 dst-ip
            10.131.8.0/21                100.88.0.9 dst-ip
            10.128.0.0/14                100.64.0.5 src-ip

$ oc exec -n openshift-ovn-kubernetes -c ovn-controller ovnkube-node-hhsx5   -- ovn-nbctl lr-route-list ovn_cluster_router
IPv4 Routes
Route Table <main>:
             10.128.8.133              10.128.8.133 dst-ip rtos-inf8
             10.129.8.107                100.88.0.5 dst-ip ecmp
             10.129.8.107                100.88.0.8 dst-ip ecmp
             10.130.10.29                100.88.0.5 dst-ip
              10.131.8.41                100.88.0.5 dst-ip
              10.131.9.28                100.88.0.5 dst-ip ecmp
              10.131.9.28                100.88.0.8 dst-ip ecmp
              10.131.9.44                100.88.0.5 dst-ip
               100.64.0.2                100.88.0.2 dst-ip
               100.64.0.3                100.88.0.3 dst-ip
               100.64.0.4                100.88.0.4 dst-ip
               100.64.0.5                100.88.0.5 dst-ip
               100.64.0.6                100.88.0.6 dst-ip
               100.64.0.8                100.88.0.8 dst-ip
               100.64.0.9                100.64.0.9 dst-ip
              100.64.0.10               100.88.0.10 dst-ip
            10.128.0.0/21                100.88.0.2 dst-ip
            10.128.8.0/21                100.88.0.6 dst-ip
           10.128.16.0/21               100.88.0.10 dst-ip
            10.129.0.0/21                100.88.0.3 dst-ip
            10.130.0.0/21                100.88.0.4 dst-ip
            10.130.8.0/21                100.88.0.8 dst-ip
            10.131.0.0/21                100.88.0.5 dst-ip
            10.128.0.0/14                100.64.0.9 src-ip
$

$ oc exec -n openshift-ovn-kubernetes -c ovn-controller ovnkube-node-qx9bh -- ovn-nbctl lr-route-list ovn_cluster_router
IPv4 Routes
Route Table <main>:
             10.128.8.133                100.88.0.9 dst-ip
             10.129.8.107                100.88.0.5 dst-ip
             10.130.10.29                100.88.0.5 dst-ip
              10.131.8.41                100.88.0.5 dst-ip
              10.131.9.28                100.88.0.5 dst-ip
              10.131.9.44                100.88.0.5 dst-ip
               100.64.0.2                100.88.0.2 dst-ip
               100.64.0.3                100.88.0.3 dst-ip
               100.64.0.4                100.88.0.4 dst-ip
               100.64.0.5                100.88.0.5 dst-ip
               100.64.0.6                100.88.0.6 dst-ip
               100.64.0.8                100.64.0.8 dst-ip
               100.64.0.9                100.88.0.9 dst-ip
              100.64.0.10               100.88.0.10 dst-ip
            10.128.0.0/21                100.88.0.2 dst-ip
            10.128.8.0/21                100.88.0.6 dst-ip
           10.128.16.0/21               100.88.0.10 dst-ip
            10.129.0.0/21                100.88.0.3 dst-ip
            10.130.0.0/21                100.88.0.4 dst-ip
            10.131.0.0/21                100.88.0.5 dst-ip
            10.131.8.0/21                100.88.0.9 dst-ip
            10.128.0.0/14                100.64.0.8 src-ip


```


### Run a nginx build a broken node (sz7rb)

```bash
$ oc adm cordon node/sendling-d0c14274-6nbvl
node/sendling-d0c14274-6nbvl already cordoned
$ oc get nodes
NAME                      STATUS                     ROLES    AGE   VERSION
sendling-d0c14274-6nbvl   Ready,SchedulingDisabled   worker   12d   v1.27.8+4fab27b
sendling-d0c14274-sz7rb   Ready                      worker   12d   v1.27.8+4fab27b
$ oc project demo
Now using project "demo" on server "https://10.32.98.158:6443".
$ oc get bc
NAME           TYPE     FROM   LATEST
nginx-sample   Source   Git    1
$ oc start-build --follow nginx-sample
build.build.openshift.io/nginx-sample-2 started
Failed to stream the build logs - to view the logs, run oc logs build/nginx-sample-2
Error: unable to stream the build logs; caused by: unable to wait for build nginx-sample-2 to run: timed out waiting for the condition
$ oc get pods -o wide
NAME                            READY   STATUS             RESTARTS   AGE    IP            NODE                      NOMINATED NODE   READINESS GATES
nginx-sample-2-build            0/1     Init:0/2           0          51s    <none>        sendling-d0c14274-sz7rb   <none>           <none>
nginx-sample-69d8c49d7d-6n42t   0/1     ImagePullBackOff   0          5m5s   10.135.0.95   sendling-d0c14274-6nbvl   <none>           <none>

$ oc get pods -o wide
NAME                            READY   STATUS                  RESTARTS   AGE     IP            NODE                      NOMINATED NODE   READINESS GATES
nginx-sample-2-build            0/1     Init:ImagePullBackOff   0          117s    10.134.0.3    sendling-d0c14274-sz7rb   <none>           <none>
nginx-sample-69d8c49d7d-6n42t   0/1     ImagePullBackOff        0          6m11s   10.135.0.95   sendling-d0c14274-6nbvl   <none>           <none>


```

**Error:**
```
Failed to pull image "quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:d2401f5d873de313176e23a61c7f4d5638e3683abc4cf20b98b82f11db73a9c0": rpc error: code = Unknown desc = copying system image from manifest list: parsing image configuration: Get "https://cdn02.quay.io/sha256/6f/6f6b4ec38c832e38d3e6d08187ed522c0413fabcbfe1f695b875f59ea00dc154?username=openshift-release-dev%2Bocm_access_fd3b76d3f252448fa62fb5587c6d22db&namespace=openshift-release-dev&Expires=1704299495&Signature=WyjvBndXGi5LtWAgX14ub0034mnNvueEqLb~~FZW9t4pcDMBCDP6kpoD7ld76q-ZzaFrerQYeWFm1NGnbyAkVnoo8zlaybwllfBrYOxxJ3JbY-YJyOZS105LVbjJaKaJhCGHldyBFyDxNiSkojI9U8OUJECW7MbqXgmqhvWOFFtOTbaeDLTnxJl~iTfhRUO4gAwYhge0uGzWiIwRogD6rPVtvsr7lkMVOYKqWp-BQKM28SPlvbYVWejSGmtPO4inQbGStmGraBGGts8x9d731Ikyq1Xc5knL4Mf8jeUkHeK~ChtGw5~JlutuPhu3v4wRLe-cznc5x8g8WEMG7dUlQA__&Key-Pair-Id=APKAJ67PQLWGCSP66DGA": dial tcp: lookup cdn02.quay.io on 172.30.0.10:53: read udp 10.131.9.28:37668->172.30.0.10:53: i/o timeout
```

After some time:

```bash

$ oc get pods -o wide
NAME                           READY   STATUS      RESTARTS   AGE     IP           NODE                      NOMINATED NODE   READINESS GATES
nginx-sample-2-build           0/1     Completed   0          4m42s   10.134.0.3   sendling-d0c14274-sz7rb   <none>           <none>
nginx-sample-d54f74d9c-2trhc   1/1     Running     0          95s     10.134.0.6   sendling-d0c14274-sz7rb   <none>           <none>
$
```

![I've node clue](https://media.giphy.com/media/zDIgL7AHiVHo6lOanB/giphy.gif)
