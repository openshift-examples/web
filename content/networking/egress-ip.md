---
title: Egress IP testing
linktitle: Egress IP testing
weight: 16400
description: TBD
---
# Egress IP testing

Namespace egress IP is a good way to fine tune access to services external to OpenShift, like databases. By default containers running on OpenShift will get IP from underlying node when they connect external services. This means that you without feature like egress IP you have to open firewall to external services from all OpenShift cluster nodes....this is not a good and security solution for production use.

With namespace egress IP you define IP address that all workload in namespace will have when they connect outside OpenShift. Official documentation can be found in [here](https://docs.openshift.com/container-platform/4.3/networking/openshift_sdn/assigning-egress-ips.html)

Following tests have been executed in OCP 4.3 cluster running on Hetzner bare metal host, [more info](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4)

What you need to provided examples

* some exernal service that has access log that shows request IP
* range or set of IP addresses that you can use in your environments
* container for testing, curl is enough

## Test environment

Tests use Hetzner environment \(CentOS 8\) so if you rung tests in other env, you might need to change some commands.

### External HTTP server

```text
$ sudo yum install -y httpd
```

You myst change binding port to 8080 since 80 is in use. Modify httpd.conf and change Listen 80 to Listen 8080

```text
$ vi /etc/httpd/conf/httpd.conf
```

```text
$ sudo systemctl start httpd
```

Create test HTML page

```text
$ cat > /var/www/html/index.html << EOF
<html>
<head/>
<body>OK</body>
</html>
EOF
```

Test that you page works

```text
$ curl http://localhost:8080/index.html
```

### Container for testing

Create project and build and deploy container for testing

```text
$ oc new-project egress-ip
$ oc new-app golang~https://github.com/sclorg/golang-ex.git
```

Once container is running \(`oc get po -w`\), you can can testing connecting to external http server. In my env I can use gateway as address since Hetzner host acts as environment gateway. I could also use external hostname registered to my host.

```text
$ oc rsh dc/golang-ex curl http://192.168.50.1:8080/index.html
```

Output should be something like this in response

```text
<html>
<head/>
<body>
OK
</body>
</html>
```

And httpd server should have something like this in access log \(`tail -10 /var/log/httpd/access_log`\)

```text
192.168.50.14 - - [19/Feb/2020:11:31:00 +0100] "GET /index.html HTTP/1.1" 200 41 "-" "curl/7.29.0"
```

IP adress 192.168.50.14 belongs to node where container is running

```text
$ oc get po -o custom-columns=NAME:.spec.containers[0].name,NODE:.spec.nodeName,POD_IP:.status.podIP,HOST_IP:.status.hostIP
NAME        NODE        POD_IP        HOST_IP
golang-ex   compute-1   10.128.2.15   192.168.50.14
```

### IP addresses to use

In hetzner environment there is 192.168.50.0/24 network reserved for OpenShift. OpenShift only use addresses between 192.168.50.2 - 192.168.50.15 so we take range from 192.168.50.128/25 for testing egress IP \(192.168.50.128-255\)

## Basic egress IP test

Setting egress IP contains two steps. Adding egress IP range and egress IPs to hostsubnet and then adding namespace egress IP to netnamespace object.

First I'll set above mentioned range to node compute-0

```text
oc patch hostsubnet compute-0 --type=merge -p '{"egressCIDRs": ["192.168.50.128/25"]}'
```

Set egress IP for namespace

```text
oc patch netnamespace egress-ip --type=merge -p '{"egressIPs": ['192.168.50.128']}'
```

To egress IP really work, you need to have IP address linked to NIC un underlying info. OpenShift SDN is managed by several operators. These operatos apply changes to hostsubnet to underlying nodes, in this compute-0

```text
$ ssh core@192.168.50.13 ip a show dev ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:a8:32:0d brd ff:ff:ff:ff:ff:ff
    inet 192.168.50.13/24 brd 192.168.50.255 scope global dynamic noprefixroute ens3
       valid_lft 2597sec preferred_lft 2597sec
    inet 192.168.50.128/24 brd 192.168.50.255 scope global secondary ens3:eip
       valid_lft forever preferred_lft forever
    inet6 fe80::328e:ab4e:72e3:39cc/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

From the output you can see that egress IP range from hostsubnet definition

Now if is test again, access log should have request from IP that we just defined.

```text
oc rsh dc/golang-ex curl http://192.168.50.1:8080/index.html
```

```text
...
192.168.50.128 - - [19/Feb/2020:12:02:35 +0100] "GET /index.html HTTP/1.1" 200 41 "-" "curl/7.29.0"
```

## Failover with single node

In previous example we assigned egress IP range to only single node. What happens if that node goes doen?

```text
virsh list
virsh shutdown ocp4-compute-0
```

Now node that had our egress IP address in NIC is down.

```text
$ oc get nodes
NAME        STATUS                     ROLES           AGE   VERSION
compute-0   NotReady                   worker          44h   v1.17.1
compute-1   Ready                      worker          44h   v1.17.1
compute-2   Ready                      worker          44h   v1.17.1
master-0    Ready,SchedulingDisabled   master,worker   44h   v1.17.1
master-1    Ready,SchedulingDisabled   master,worker   44h   v1.17.1
master-2    Ready,SchedulingDisabled   master,worker   44h   v1.17.1
```

Now lets run test again.

```text
oc rsh dc/golang-ex curl http://192.168.50.1:8080/index.html
```

Test fails since there is not network that can carry request out.

### Failover with 2+ nodes

How to fix this, attach that egress range to 2+ nodes.

```text
oc patch hostsubnet compute-1 --type=merge -p '{"egressCIDRs": ["192.168.50.128/25"]}'
oc patch hostsubnet compute-2 --type=merge -p '{"egressCIDRs": ["192.168.50.128/25"]}'
```

Check that all nods are running and Ready and check that all computes nodes have egress CIDR defined

```text
$ oc get hostsubnet
NAME        HOST        HOST IP         SUBNET          EGRESS CIDRS          EGRESS IPS
compute-0   compute-0   192.168.50.13   10.129.2.0/23   [192.168.50.128/25]
compute-1   compute-1   192.168.50.14   10.128.2.0/23   [192.168.50.128/25]   [192.168.50.128]
compute-2   compute-2   192.168.50.15   10.131.0.0/23   [192.168.50.128/25]
master-0    master-0    192.168.50.10   10.130.0.0/23
master-1    master-1    192.168.50.11   10.128.0.0/23
master-2    master-2    192.168.50.12   10.129.0.0/23
```

Openshift second terminal and run our test in a loop

```text
while true; do oc rsh dc/golang-ex curl http://192.168.50.1:8080/index.html ;sleep 2; done
```

Next shutdown node where egress IP is bound, in my case it is compute-1.

Once OpenShift notices that node with egress IP is down, IP will be moved to new node that has egress range defined.

```text
$ oc get hostsubnet
NAME        HOST        HOST IP         SUBNET          EGRESS CIDRS          EGRESS IPS
compute-0   compute-0   192.168.50.13   10.129.2.0/23   [192.168.50.128/25]
compute-1   compute-1   192.168.50.14   10.128.2.0/23   [192.168.50.128/25]
compute-2   compute-2   192.168.50.15   10.131.0.0/23   [192.168.50.128/25]   [192.168.50.128]
master-0    master-0    192.168.50.10   10.130.0.0/23
master-1    master-1    192.168.50.11   10.128.0.0/23
master-2    master-2    192.168.50.12   10.129.0.0/23

$ ssh core@192.168.50.15 ip a show dev ens3
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 52:54:00:a8:32:0f brd ff:ff:ff:ff:ff:ff
    inet 192.168.50.15/24 brd 192.168.50.255 scope global dynamic noprefixroute ens3
       valid_lft 3195sec preferred_lft 3195sec
    inet 192.168.50.128/24 brd 192.168.50.255 scope global secondary ens3:eip
       valid_lft forever preferred_lft forever
    inet6 fe80::2758:fcdc:4046:5765/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
```

## Automated Management of Egress IPs

Egress IP management can be automated with Operator based approach. Here is a blog post about implementing that.

[Fully Automated Management of Egress IPs with the egressip-ipam-operator](https://www.openshift.com/blog/fully-automated-management-of-egress-ips-with-the-egressip-ipam-operator/)