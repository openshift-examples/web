---
title: Troubleshooting
linktitle: Troubleshooting
description: Troubleshooting
tags:
  - troubleshooting
ignore_macros: true
---
# Troubleshooting

## The openshift-console is not coming up
```log
E1011 08:07:56.183305       1 auth.go:231] error contacting auth provider (retrying in 10s): request to OAuth issuer endpoint https://oauth-openshift.apps.hal.openshift.airgapped/oauth/token failed: Head "https://oauth-openshift.apps.hal.openshift.airgapped": EOF
E1011 08:08:06.187357       1 auth.go:231] error contacting auth provider (retrying in 10s): request to OAuth issuer endpoint https://oauth-openshift.apps.hal.openshift.airgapped/oauth/token failed: Head "https://oauth-openshift.apps.hal.openshift.airgapped": EOF
```

**Issue**: Router pods scheduled on master.

**Solution**: Find and delete pods using the below command:
```bash
oc get pod -n openshift-ingress -o wide
oc delete pod router-default-65c56bb644-2ldfp router-default-65c56bb644-lqznd -n openshift-ingress
```

## The openshift-console is not coming up
```log
oc describe pod <podname>

FailedScheduling: 0/7 nodes are available: 3 nodes had taint, that the pod didn’t tolerate (node-role.kubernetes.io/master), 4 insufficient cpu
```

**Issue**: Because of insufficient CPU the pod(s) cannot be scheduled.

**Solution**: Allocate more physical or virtual CPU or use the Cluster Resource Override Operator to override the ratio between requests and limits set on containers/ pods:
1.  Install the [Cluster Resource Override Operator](https://docs.openshift.com/container-platform/4.10/nodes/clusters/nodes-cluster-overcommit.html)
2.  Add the below custom resource definition
```bash
apiVersion: operator.autoscaling.openshift.io/v1
kind: ClusterResourceOverride
metadata:
  name: cluster
spec:
  podResourceOverride:
    spec:
       cpuRequestToLimitPercent: 25
```
If a container CPU limit has been specified or defaulted, this will override the CPU request to 25% percentage of the limit.

3. Apply the following label to the Namespace object for each project (overrides can be enabled per-project):
```
apiVersion: v1
kind: Namespace
metadata:
....
  labels:
    clusterresourceoverrides.admission.autoscaling.openshift.io/enabled: "true"
....
```

## The bootstrap is running but the customer can't pull from the mirror registry 
```log
Error pulling candidate abc.def.ghi/company-openshift-docker/openshift-release-dev/ocp-release@sha256:97410a5db655a9d3017b735c2c0747c849d09ff551765e49d5272b80c024a844: initializing source docker://abc.def.ghi/company-openshift-docker/openshift-release-dev/ocp-release@sha256:97410a5db655a9d3017b735c2c0747c849d09ff551765e49d5272b80c024a844: pinging container registry abc.def.ghi: Get "https://abc.def.ghi/v2/ <https://abc.def.ghi/v2/> ": x509: certificate signed by unknown authority

Error: initializing source docker://abc.def.ghi/company-openshift-docker/openshift-release-dev/ocp-release@sha256:97410a5db655a9d3017b735c2c0747c849d09ff551765e49d5272b80c024a844: pinging container registry abc.def.ghi: Get "https://abc.def.ghi/v2/ <https://abc.def.ghi/v2/> ": x509: certificate signed by unknown authority
```

**Issue**: The mirror registry's certificate isn't trusted. 

**Solution**: Use curl and openssl to identify the correct certificate/chain of certificates needed to be able to securely connect to the mirror registry and add them to the additionalTrustBundle section inside the `install-config.yaml` file with the right intendation, for [example](https://docs.openshift.com/container-platform/4.11/installing/installing_vsphere/installing-restricted-networks-installer-provisioned-vsphere.html#installation-installer-provisioned-vsphere-config-yaml_installing-restricted-networks-installer-provisioned-vsphere).


## Ignition fails - connection refused errors during the installation process
```log
#Checking the bootstrap via journalctl shows below error:
Sep 13 11:58:08 v0004369.abc.def.ghi cluster-bootstrap[46455]: [#602]
failed to fetch discovery: Get "https://localhost:6443/api?timeout=32s":
dial tcp [::1]:6443: connect: connection refused
Sep 13 11:58:08 v0004369.abc.def.ghi bootkube.sh[46444]: [#602] failed to
fetch discovery: Get "https://localhost:6443/api?timeout=32s": dial tcp
[::1]:6443: connect: connection refused
```

**Problem determination**: 
Check whether the Kubernetes API (`https://api.<cluster-id>.<domain>:port`) is accessible. This helps to verify that the DNS resolution on the bootstrap server is set up correctly.
6443 is the (API) port used by all nodes to communicate with the control plane (master nodes). For reference see [Network connectivity requirements](https://docs.openshift.com/container-platform/4.11/installing/installing_vsphere/installing-vsphere-installer-provisioned.html#installation-vsphere-installer-network-requirements_installing-vsphere-installer-provisioned).
  
```bash
#$ curl -k -I -v https://api.<cluster-id>.<domain>:port

#The result output hinted at a certificate issue
[core@v0004369 ~]$ curl -k -I -v https://api.<cluster-id>.<domain>:port 
* Rebuilt URL to: https://api.<cluster-id>.<domain>:port/ 
*  Trying x.x.x.x...
* TCP_NODELAY set
* Connected to api.<cluster-id>.<domain> (<ip address>) port 6443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/pki/tls/certs/ca-bundle.crt
 CApath: none
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to
api.<cluster-id>.<domain>:6443
curl: (35) OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to
api.<cluster-id>.<domain>:6443
```
  
Run the below debug command from the OpenShift installation directory. This command can be used to follow the installation process.
```bash
$ openshift-install wait-for bootstrap-complete --log-level debug

#The result output hinted at a certificate issue
[openshift@v0004314 cluster]$ openshift-install wait-for bootstrap-complete
--log-level debug
DEBUG OpenShift Installer 4.11.1
DEBUG Built from commit 1d2450c520b70765b53b71da5e8544657d50d6e2
INFO Waiting up to 20m0s (until 3:28PM) for the Kubernetes API at
https:api.<cluster-id>.<domain>:6443 ...
DEBUG Still waiting for the Kubernetes API: Get "https:api.<cluster-id>.<domain>:6443": EOF
DEBUG Still waiting for the Kubernetes API: Get "https:api.<cluster-id>.<domain>:6443": x509: certificate has
expired or is not yet valid: current time 2022-09-13T15:10:07+02:00 is
after 2022-09-10T08:45:15Z
DEBUG Still waiting for the Kubernetes API: Get "https://api.<cluster-id>.<domain>:6443": x509: certificate has
expired or is not yet valid: current time 2022-09-13T15:10:38+02:00 is
after 2022-09-10T08:45:15Z
DEBUG Still waiting for the Kubernetes API: Get "https://api.<cluster-id>.<domain>:6443": EOF
```

**Issue**: The Ignition config files that the openshift-install program generates contain certificates that expire after 24 hours. Expired certificates cause the installation to fail.  

**Solution**: 
Verify the validity of the certificate being presented by the bootstrap node.
```bash
openssl s_client -connect api-int.cluster.fqdn:22623 | openssl x509 -noout -text
```

Check that all certificates are valid, especially the certificates from which the ignition files are created. If the openshift-install create ignition-configs command needs to be re-run, then delete **all** files - including **hidden** files - except install_config.yaml and openshift-install. Otherwise, the date of the certificates could be pinned to the first run, i.e. the certificates have expired.

**Note:**
It is recommended that you use Ignition config files within 12 hours after they are generated because the 24-hour certificate rotates from 16 to 22 hours after the cluster is installed

For reference, please see 
* [Creating the Kubernetes manifest and Ignition config files](https://docs.openshift.com/container-platform/4.11/installing/installing_platform_agnostic/installing-platform-agnostic.html#installation-user-infra-generate-k8s-manifest-ignition_installing-platform-agnostic)
* [Masters and Workers Fail to Ignite Reporting Error 'x509: certificate has expired or not yet valid'](https://access.redhat.com/solutions/4355651)


## Troubleshooting network issues
```bash
$ oc get nodes -o wide
$ oc get events -n openshift-sdn
$ oc get co
```

[Move networking resources to the control plane on vsphere](https://access.redhat.com/solutions/6753541)

[OCP 4 Node not ready after cluster upgrade or node restart](https://access.redhat.com/solutions/5808731)


## Worker nodes are not visible when running oc get nodes
`oc get nodes` only shows master nodes.

**Issue**: The nodes' certificate requests haven't been approved. 

**Solution**: 
The new worker node(s) will still be missing or in pending state. Add them by signing the respective client and server CSR requests. Run `oc get csr` and then sign each request.

```bash
oc get csr
oc adm certificate approve <csr_name> 
```

There will be multiple CSRs created per worker, so run the commands above multiple times until the workers show up as ready.

Alternatively, to approve all pending CSRs, run the following command:
```
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

After all client and server CSRs have been approved, the machines should have the ready status. Verify this by running the following command:
```
oc get nodes
```

## Installation using OVA template fails

**Issue**: The OVA image has been started prior to cloning.

**Solution**: 
Create a new template for the OVA image and then clone the template as needed. Starting the OVA image prior to cloning will kick off the ignition process and, as a result, the ignition of the templates fails.


## Troubleshooting ingress issues
To check the status of the ingress operator use
```bash
$ oc get co
$ oc get ingresscontroller/default -o yaml -n openshift-ingress-operator
```

Place a nodeSeclector of this deployment on a master node provided that master nodes are running and ready. To verify that masters are unschedulable ensure that 
the masterSchedulable field is set to false.
```bash
$ oc edit schedulers.config.openshift.io cluster

#The result is something like
apiVersion: config.openshift.io/v1
kind: Scheduler
metadata:
  creationTimestamp: "2022-09-11T07:02:04Z"
  generation: 1
  name: cluster
  resourceVersion: "623"
  uid: 3b595176-4b45-4ac4-99d7-bd09adc2eb3a
spec:
  mastersSchedulable: false
  policy:
    name: ""
status: {} 
```

## Troubleshooting node startup issues
To monitor machine-config-operator logs in case any node fails to start:
```bash
$ oc get pods -n openshift-machine-config-operator
$ oc logs -f -n openshift-machine-config-operator machine-config-daemon-<XXXX> -c machine-config-daemon
```

[OpenShift Container Platform 4: How does Machine Config Pool work? ](https://www.redhat.com/en/blog/openshift-container-platform-4-how-does-machine-config-pool-work#:~:text=What%20is%20a%20Machine%20Config,up%20to%20date%20and%20configured)


## Troubleshooting ICSP related node startup issues
To check the content of `/etc/containers/registries.conf` on each node use
```bash
$ oc debug node/<worker or master node>
#chroot /host
# less /etc/containers/registries.conf
```

If `/etc/containers/registries.conf` changes, do the nodes purge their internal cache?
NO - If a new container is deployed and if the image requested is not on node the image will be pull from the “mirror” registry mentioned in /etc/containers/registries. This file is just for crio to download the image to the correct location.


## Resizing the VM disk

https://unix.stackexchange.com/questions/678677/in-an-ubuntu-vm-in-vmware-i-increased-the-hard-disk-space-how-do-i-add-that-to


## How to delete/destroy a failed installation
```bash
./openshift-install destroy cluster --dir <installation_directory> --log-level info 
```
[Reference](https://docs.openshift.com/container-platform/4.11/installing/installing_ibm_cloud_public/uninstalling-cluster-ibm-cloud.html)
