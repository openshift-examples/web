# MachineSets Debugging

## Check config-daemon pod log

```bash
$ oc get pods -o wide -n openshift-machine-config-operator
NAME                                         READY   STATUS    RESTARTS   AGE    IP              NODE        NOMINATED NODE   READINESS GATES
etcd-quorum-guard-6ffd665dfd-jjlnm           1/1     Running   0          7d5h   192.168.55.10   master-0    <none>           <none>
etcd-quorum-guard-6ffd665dfd-nrt2q           1/1     Running   0          7d5h   192.168.55.12   master-2    <none>           <none>
etcd-quorum-guard-6ffd665dfd-nwn6w           1/1     Running   0          7d5h   192.168.55.11   master-1    <none>           <none>
machine-config-controller-6fdf949978-b6z2z   1/1     Running   1          7d5h   10.129.0.3      master-1    <none>           <none>
machine-config-daemon-c6c8d                  2/2     Running   0          7d5h   192.168.55.13   compute-0   <none>           <none>
machine-config-daemon-fphbh                  2/2     Running   0          7d5h   192.168.55.10   master-0    <none>           <none>
machine-config-daemon-pvvwh                  2/2     Running   0          7d5h   192.168.55.14   compute-1   <none>           <none>
machine-config-daemon-xmd9v                  2/2     Running   0          7d5h   192.168.55.11   master-1    <none>           <none>
machine-config-daemon-zlcm2                  2/2     Running   0          7d5h   192.168.55.15   compute-2   <none>           <none>
machine-config-daemon-zslvq                  2/2     Running   0          7d5h   192.168.55.12   master-2    <none>           <none>
machine-config-operator-94994fb57-z775v      1/1     Running   1          7d5h   10.128.0.10     master-0    <none>           <none>
machine-config-server-hrt28                  1/1     Running   0          7d5h   192.168.55.12   master-2    <none>           <none>
machine-config-server-nvtzs                  1/1     Running   0          7d5h   192.168.55.11   master-1    <none>           <none>
machine-config-server-zk2fc                  1/1     Running   0          7d5h   192.168.55.10   master-0    <none>           <none>

$ oc logs -n openshift-machine-config-operator machine-config-daemon-zlcm2 -c machine-config-daemon
I0722 08:59:47.489287    3820 start.go:74] Version: v4.4.0-202005180840-dirty (480accd5d4f631d34e560aa5c8a3dfab0c7bbe27)
I0722 08:59:47.492281    3820 start.go:84] Calling chroot("/rootfs")
I0722 08:59:47.492553    3820 rpm-ostree.go:366] Running captured: rpm-ostree status --json
I0722 08:59:47.976562    3820 daemon.go:209] Booted osImageURL: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:b397960b7cc14c2e2603111b7385c6e8e4b0f683f9873cd9252a789175e5c4e1 (44.81.202005180831-0)
I0722 08:59:47.980187    3820 metrics.go:106] Registering Prometheus metrics
I0722 08:59:47.980274    3820 metrics.go:111] Starting metrics listener on 127.0.0.1:8797
I0722 08:59:47.980510    3820 update.go:1291] Starting to manage node: compute-2
I0722 08:59:47.988656    3820 rpm-ostree.go:366] Running captured: rpm-ostree status
I0722 08:59:48.056755    3820 daemon.go:778] State: idle
AutomaticUpdates: disabled
Deployments:
* pivot://quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:b397960b7cc14c2e2603111b7385c6e8e4b0f683f9873cd9252a789175e5c4e1
              CustomOrigin: Managed by machine-config-operator
                   Version: 44.81.202005180831-0 (2020-05-18T08:38:30Z)

  ostree://2062bce64e4932160feb58ce4976a885172d3f1017dc01f09177504bd55e035b
                   Version: 44.81.202004260825-0 (2020-04-26T08:30:26Z)
I0722 08:59:48.056786    3820 rpm-ostree.go:366] Running captured: journalctl --list-boots
I0722 08:59:48.067098    3820 daemon.go:785] journalctl --list-boots:
-1 e4e923bf2a394325a93d1f2fe662580a Wed 2020-07-22 08:44:48 UTC—Wed 2020-07-22 08:57:35 UTC
 0 aa38c334768a48be87af8e16941bc34a Wed 2020-07-22 08:57:44 UTC—Wed 2020-07-22 08:59:48 UTC
I0722 08:59:48.067127    3820 daemon.go:528] Starting MachineConfigDaemon
I0722 08:59:48.067270    3820 daemon.go:535] Enabling Kubelet Healthz Monitor
I0722 08:59:53.939985    3820 node.go:24] No machineconfiguration.openshift.io/currentConfig annotation on node compute-2: map[volumes.kubernetes.io/controller-managed-attach-detach:true], in cluster bootstrap, loading initial node annotation from /etc/machine-config-daemon/node-annotations.json
I0722 08:59:53.940549    3820 node.go:45] Setting initial node config: rendered-worker-fe5cc8b490c8a4803a6f8ec96611bda2
I0722 08:59:53.971509    3820 daemon.go:696] In bootstrap mode
I0722 08:59:53.971594    3820 daemon.go:724] Current+desired config: rendered-worker-fe5cc8b490c8a4803a6f8ec96611bda2
I0722 08:59:53.979288    3820 daemon.go:917] No bootstrap pivot required; unlinking bootstrap node annotations
I0722 08:59:53.979438    3820 daemon.go:955] Validating against pending config rendered-worker-fe5cc8b490c8a4803a6f8ec96611bda2
I0722 08:59:53.981831    3820 daemon.go:971] Validated on-disk state
I0722 08:59:54.016509    3820 daemon.go:1005] Completing pending config rendered-worker-fe5cc8b490c8a4803a6f8ec96611bda2
I0722 08:59:54.017021    3820 update.go:1291] completed update for config rendered-worker-fe5cc8b490c8a4803a6f8ec96611bda2
I0722 08:59:54.021653    3820 daemon.go:1021] In desired config rendered-worker-fe5cc8b490c8a4803a6f8ec96611bda2

```

## In case of a cluster upgrade: Check download pod

```bash
$ oc get pods -n openshift-cluster-version
NAME                                        READY   STATUS      RESTARTS   AGE
cluster-version-operator-5c97586d4f-9hqwn   1/1     Running     0          2m25s
version-4.4.13-pwgd4-mhc2q                  0/1     Completed   0          2m59s
```