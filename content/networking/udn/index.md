---
title: User-defined networks
linktitle: User-defined networks
description: User-defined networks (UDN)
tags: ['UDN','v4.18']
---
# User-defined networks (UDN)

![](udn.drawio)

Official documentation:

* [16.2.1. About user-defined networks](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/networking/multiple-networks#about-user-defined-networks)

Resources:

* <https://github.com/maiqueb/fosdem2025-p-udn/tree/main>
* <https://asciinema.org/a/699323>
* `203.0.113.0/24` - [IANA IPv4 Special-Purpose Address Registry](https://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml)

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.18.8|
|OpenShift Virt|v4.18.2|

![](overview.drawio)

## Namespaces

|Tanent|Namespace|Color|UDN or CUDN|P-UDN IP Range|
|---|---|---|---|---|
|tanent-1|namespace-1|red|UDN (udn-1)|`192.0.2.0/24`|
|tanent-2|namespace-2|green|UDN (udn-2)|`10.255.0.0/16`|
|tanent-3|namespace-3|blue|CUDN (cudn-3)|`203.0.113.0/24`|
|tanent-4|namespace-4|orange|CUDN (cudn-3)|`203.0.113.0/24`|

## Deploy

```shell
oc apply -k overlays/tentant-1
oc apply -k overlays/tentant-2
oc apply -k overlays/tentant-3
```

```shell
$ oc get namespaces -l tentant -L tentant
NAME          STATUS   AGE     TENTANT
namespace-1   Active   4m1s    tentant-1
namespace-2   Active   3m51s   tentant-2
namespace-3   Active   3m14s   tentant-3
namespace-4   Active   3m13s   tentant-3

$ oc get pods -o go-template-file=podlist-with-p-udn.gotemplate -A -l tentant  | jq ' (.[] | [.node,.namespace, .udn[1].ips[0], .udn[0].ips[0], .name]) | @tsv' -r
ocp1-worker-0   namespace-1     192.0.2.10      10.131.0.201    agnhost-7f79bb7dc-t8rfg
ocp1-worker-0   namespace-1     192.0.2.9       10.131.0.202    rhel-support-tools-7c89889f94-wq2gj
ocp1-worker-1   namespace-1     192.0.2.17      10.128.3.55     simple-http-server-bb9ccffd4-74j47
ocp1-worker-2   namespace-1     192.0.2.11      10.129.2.131    simple-http-server-bb9ccffd4-jq4bb
ocp1-worker-0   namespace-1     192.0.2.16      10.131.0.223    simple-http-server-bb9ccffd4-xll6x
ocp1-worker-2   namespace-1     192.0.2.19      10.129.2.143    virt-launcher-simple-httpd-vm-5wxpj
ocp1-worker-0   namespace-2     10.255.2.6      10.131.0.220    agnhost-59964fb864-hp46z
ocp1-worker-0   namespace-2     10.255.2.8      10.131.0.221    rhel-support-tools-7cfb68d78f-89jkl
ocp1-worker-0   namespace-2     10.255.2.7      10.131.0.222    simple-http-server-7c567b8c4c-2pph6
ocp1-worker-1   namespace-2     10.255.3.4      10.128.3.54     simple-http-server-7c567b8c4c-brqtl
ocp1-worker-2   namespace-2     10.255.0.4      10.129.2.137    simple-http-server-7c567b8c4c-mjgwc
ocp1-worker-1   namespace-2     10.255.3.8      10.128.3.62     virt-launcher-simple-httpd-vm-w6hwn
ocp1-worker-2   namespace-3     203.0.113.22    10.129.2.135    agnhost-f4b987769-kcmvs
ocp1-worker-0   namespace-3     203.0.113.25    10.131.0.207    rhel-support-tools-5b999555b4-w2qv5
ocp1-worker-2   namespace-3     203.0.113.23    10.129.2.134    simple-http-server-6b84977478-7kkhd
ocp1-worker-1   namespace-3     203.0.113.29    10.128.3.56     simple-http-server-6b84977478-pbj4d
ocp1-worker-0   namespace-3     203.0.113.30    10.131.0.224    simple-http-server-6b84977478-wn6kl
ocp1-worker-0   namespace-3     203.0.113.39    10.131.1.39     virt-launcher-simple-httpd-vm-h8xr7
ocp1-worker-0   namespace-4     203.0.113.26    10.131.0.203    agnhost-f4b987769-vxtl7
ocp1-worker-0   namespace-4     203.0.113.24    10.131.0.204    rhel-support-tools-5b999555b4-5kgbs
ocp1-worker-0   namespace-4     203.0.113.33    10.131.0.225    simple-http-server-6b84977478-mqhj4
ocp1-worker-2   namespace-4     203.0.113.21    10.129.2.133    simple-http-server-6b84977478-rnc2c
ocp1-worker-1   namespace-4     203.0.113.35    10.128.3.57     simple-http-server-6b84977478-v7xhz
ocp1-worker-2   namespace-4     203.0.113.40    10.129.2.142    virt-launcher-simple-httpd-vm-lk4rc
$ oc get vmi -l tentant -A
NAMESPACE     NAME              AGE     PHASE     IP             NODENAME        READY
namespace-1   simple-httpd-vm   93s     Running   192.0.2.19     ocp1-worker-2   True
namespace-2   simple-httpd-vm   87s     Running   10.255.3.8     ocp1-worker-1   True
namespace-3   simple-httpd-vm   2m43s   Running   203.0.113.39   ocp1-worker-0   True
namespace-4   simple-httpd-vm   2m42s   Running   203.0.113.40   ocp1-worker-2   True
```

* Why is ip's of UDN nocht in pod status `podIPs` ?

## Testing

### ✅ Network Policy

```shell
$ oc get vmi -l tentant=tentant -A
NAMESPACE     NAME              AGE   PHASE     IP             NODENAME        READY
namespace-3   simple-httpd-vm   32m   Running   203.0.113.41   ocp1-worker-0   True
namespace-4   simple-httpd-vm   32m   Running   203.0.113.42   ocp1-worker-2   True
$  virtctl console -n namespace-3 simple-httpd-vm
Successfully connected to simple-httpd-vm console. The escape sequence is ^]

simple-httpd-vm login: fedora
Password:
Last login: Wed May  7 06:57:10 on ttyS0
[systemd]
Failed Units: 1
  cloud-final.service
[fedora@simple-httpd-vm ~]$ ip -br a
lo               UNKNOWN        127.0.0.1/8 ::1/128
eth0             UP             203.0.113.41/24 fe80::858:cbff:fe00:7129/64
[fedora@simple-httpd-vm ~]$ ping -c4 203.0.113.42
PING 203.0.113.42 (203.0.113.42) 56(84) bytes of data.
64 bytes from 203.0.113.42: icmp_seq=1 ttl=64 time=7.58 ms
64 bytes from 203.0.113.42: icmp_seq=2 ttl=64 time=9.58 ms
64 bytes from 203.0.113.42: icmp_seq=3 ttl=64 time=1.47 ms
64 bytes from 203.0.113.42: icmp_seq=4 ttl=64 time=1.80 ms

--- 203.0.113.42 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3007ms
rtt min/avg/max/mdev = 1.474/5.107/9.581/3.545 ms
[fedora@simple-httpd-vm ~]$ curl -I http://203.0.113.42/
HTTP/1.1 403 Forbidden
Date: Wed, 07 May 2025 07:06:54 GMT
Server: Apache/2.4.46 (Fedora)
Last-Modified: Tue, 28 Jan 2020 18:21:43 GMT
ETag: "15bc-59d374bbd1bc0"
Accept-Ranges: bytes
Content-Length: 5564
Content-Type: text/html; charset=UTF-8
```

Apply Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-other-namespaces
  namespace: namespace-4
spec:
  podSelector: null
  ingress:
    - from:
        - podSelector: {}
```

```shell
[fedora@simple-httpd-vm ~]$ curl --connect-timeout 1 -I http://203.0.113.42/
curl: (28) Connection timed out after 1001 milliseconds
[fedora@simple-httpd-vm ~]$
```

### ⏱️ MultiNetworkPolicy

* Not tested yet

### ✅/⚠️ Services

```yaml
$ oc get svc -n namespace-3
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
agnhost              ClusterIP   172.30.222.33    <none>        9000/TCP   16h
simple-http-server   ClusterIP   172.30.209.160   <none>        8080/TCP   16h
simple-httpd-vm      ClusterIP   172.30.196.254   <none>        80/TCP     66m
[fedora@simple-httpd-vm ~]$ getent ahosts simple-httpd-vm.namespace-3
r.local
172.30.196.254  STREAM simple-httpd-vm.namespace-3.svc.cluster.local
172.30.196.254  DGRAM
172.30.196.254  RAW
[fedora@simple-httpd-vm ~]$ curl http://simple-httpd-vm.namespace-3.svc.cluster.local.
curl: (7) Failed to connect to simple-httpd-vm.namespace-3.svc.cluster.local port 80: Connection refused
```

* ❌ Pod -> Service -> VM with L2Bridge in UDN
* ✅ Pod -> Service -> Pod

### ✅ Ingress

Works only because of pod annotation

```yaml
        k8s.ovn.org/open-default-ports: |
          - protocol: tcp
            port: 8080
```

### ✅ Liveness/Readyness probes

```shell
oc rsh simple-http-server-6b84977478-chvj9
sh-5.1$ rm /www/readiness-probe
rm: remove write-protected regular empty file '/www/readiness-probe'? y
sh-5.1$

$ oc get pods --watch
simple-http-server-6b84977478-chvj9   1/1     Running             0             4s
simple-http-server-6b84977478-chvj9   0/1     Running             0             19s
```

### ✅ Direct access

Check network policy part

### ✅ VM Live Migration

```shell
$ oc get vmi --watch
NAME              AGE   PHASE     IP             NODENAME        READY
simple-httpd-vm   66m   Running   203.0.113.41   ocp1-worker-0   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-0   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-0   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-0   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-0   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-0   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-2   True
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-2   False
simple-httpd-vm   67m   Running   203.0.113.41   ocp1-worker-2   True
```

### ⏱️ Secondary-UDN

* Not tested yet

### ✅ Layer2

* Tentant 1 is Layer 2

### ✅ Layer3

* Tentant 2 is Layer 3

### ⏱️ Localnet (Available with 4.19)
