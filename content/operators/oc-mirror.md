---
title: oc mirror
linktitle: oc mirror
description: Some details about oc mirror
tags: ['air-gapped','disconnect','oc-mirror']
---
# oc mirror

## oc mirror vs grpcurl

* <https://github.com/operator-framework/operator-registry#using-the-catalog-locally>

|oc mirror|grpcurl|
|---|---|
|`oc mirror list operators --catalog=..`|`grpcurl -plaintext localhost:50051 api.Registry/ListPackages`|
|`oc mirror list operators --catalog=.. --package=kubernetes-nmstate-operator`|`grpcurl -plaintext -d '{"name":"kubernetes-nmstate-operator"}' localhost:50051 api.Registry/GetPackage` |

```bash
$ time oc mirror list operators --catalogs --version=4.12
Available OpenShift OperatorHub catalogs:
OpenShift 4.12:
registry.redhat.io/redhat/redhat-operator-index:v4.12
registry.redhat.io/redhat/certified-operator-index:v4.12
registry.redhat.io/redhat/community-operator-index:v4.12
registry.redhat.io/redhat/redhat-marketplace-index:v4.12

real  1m10.363s
user  0m0.208s
sys  0m0.085s
$ time oc mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.12
NAME                                          DISPLAY NAME                                                 DEFAULT CHANNEL
3scale-operator                               Red Hat Integration - 3scale - Managed Application Services  threescale-mas
advanced-cluster-management                   Advanced Cluster Management for Kubernetes                   release-2.7
amq-broker-rhel8                              Red Hat Integration - AMQ Broker for RHEL 8 (Multiarch)      7.10.x
amq-online                                    Red Hat Integration - AMQ Online                             stable
amq-streams                                   Red Hat Integration - AMQ Streams                            stable
amq7-interconnect-operator                    Red Hat Integration - AMQ Interconnect                       1.10.x
ansible-automation-platform-operator          Ansible Automation Platform                                  stable-2.3-cluster-scoped
ansible-cloud-addons-operator                 Ansible Cloud Addons                                         stable-2.3-cluster-scoped
apicast-operator                              Red Hat Integration - 3scale APIcast gateway                 threescale-2.13
aws-efs-csi-driver-operator                   AWS EFS CSI Driver Operator                                  stable
aws-load-balancer-operator                    AWS Load Balancer Operator                                   stable-v0
bamoe-businessautomation-operator             IBM Business Automation                                      8.x-stable
bamoe-kogito-operator                         IBM BAMOE Kogito Operator                                    8.x
bare-metal-event-relay                        Bare Metal Event Relay                                       stable
businessautomation-operator                   Business Automation                                          stable
cincinnati-operator                           OpenShift Update Service                                     v1
cluster-kube-descheduler-operator             Kube Descheduler Operator                                    stable
cluster-logging                               Red Hat OpenShift Logging                                    stable
clusterresourceoverride                       ClusterResourceOverride Operator                             stable
compliance-operator                           Compliance Operator                                          release-0.1
container-security-operator                   Red Hat Quay Container Security Operator                     stable-3.8
costmanagement-metrics-operator               Cost Management Metrics Operator                             stable
cryostat-operator                             Red Hat build of Cryostat                                    stable
datagrid                                      Data Grid                                                    8.4.x
devspaces                                     Red Hat OpenShift Dev Spaces                                 stable
devworkspace-operator                         DevWorkspace Operator                                        fast
dpu-network-operator                          DPU Network Operator                                         stable
eap                                           JBoss EAP                                                    stable
elasticsearch-operator                        OpenShift Elasticsearch Operator                             stable
external-dns-operator                         ExternalDNS Operator                                         stable-v1
file-integrity-operator                       File Integrity Operator                                      v1
fuse-apicurito                                Red Hat Integration - API Designer                           fuse-apicurito-7.11.x
fuse-console                                  Red Hat Integration - Fuse Console                           7.11.x
fuse-online                                   Red Hat Integration - Fuse Online                            latest
gatekeeper-operator-product                   Gatekeeper Operator                                          stable
gcp-filestore-csi-driver-operator             GCP Filestore CSI Driver Operator                            stable
ingress-node-firewall                         Ingress Node Firewall Operator                               stable
jaeger-product                                Red Hat OpenShift distributed tracing platform               stable
jws-operator                                  JWS Operator                                                 alpha
kernel-module-management                      Kernel Module Management                                     stable
kernel-module-management-hub                  Kernel Module Management (Hub)                               stable
kiali-ossm                                    Kiali Operator                                               stable
kubernetes-nmstate-operator                   Kubernetes NMState Operator                                  stable
kubevirt-hyperconverged                       OpenShift Virtualization                                     stable
local-storage-operator                        Local Storage                                                stable
loki-operator                                 Loki Operator                                                stable
lvms-operator                                 LVM Storage                                                  stable-4.12
mcg-operator                                  NooBaa Operator                                              stable-4.12
metallb-operator                              MetalLB Operator                                             stable
mta-operator                                  Migration Toolkit for Applications Operator                  stable-v6.0
mtc-operator                                  Migration Toolkit for Containers Operator                    release-v1.7
mtr-operator                                  Migration Toolkit for Runtimes Operator                      alpha
mtv-operator                                  Migration Toolkit for Virtualization Operator                release-v2.3
multicluster-engine                           multicluster engine for Kubernetes                           stable-2.2
netobserv-operator                            Network observability                                        v1.0.x
nfd                                           Node Feature Discovery Operator                              stable
node-healthcheck-operator                     Node Health Check Operator                                   stable
node-maintenance-operator                     Node Maintenance Operator                                    stable
node-observability-operator                   Node Observability Operator                                  alpha
numaresources-operator                        numaresources-operator                                       4.12
ocs-operator                                  OpenShift Container Storage                                  stable-4.12
odf-csi-addons-operator                       CSI Addons                                                   stable-4.12
odf-multicluster-orchestrator                 ODF Multicluster Orchestrator                                stable-4.12
odf-operator                                  OpenShift Data Foundation                                    stable-4.12
odr-cluster-operator                          Openshift DR Cluster Operator                                stable-4.12
odr-hub-operator                              Openshift DR Hub Operator                                    stable-4.12
openshift-cert-manager-operator               cert-manager Operator for Red Hat OpenShift                  tech-preview
openshift-custom-metrics-autoscaler-operator  Custom Metrics Autoscaler                                    stable
openshift-gitops-operator                     Red Hat OpenShift GitOps                                     latest
openshift-pipelines-operator-rh               Red Hat OpenShift Pipelines                                  latest
openshift-secondary-scheduler-operator        Secondary Scheduler Operator for Red Hat OpenShift           stable
opentelemetry-product                         Red Hat OpenShift distributed tracing data collection        stable
ptp-operator                                  PTP Operator                                                 stable
quay-bridge-operator                          Red Hat Quay Bridge Operator                                 stable-3.8
quay-operator                                 Red Hat Quay                                                 stable-3.8
red-hat-camel-k                               Red Hat Integration - Camel K                                1.8.x
redhat-oadp-operator                          OADP Operator                                                stable-1.1
rh-service-binding-operator                   Service Binding Operator                                     stable
rhacs-operator                                Advanced Cluster Security for Kubernetes                     latest
rhods-operator                                Red Hat OpenShift Data Science                               stable
rhods-prometheus-operator                     Prometheus Operator                                          beta
rhpam-kogito-operator                         RHPAM Kogito Operator                                        7.x
rhsso-operator                                Red Hat Single Sign-On Operator                              stable
sandboxed-containers-operator                 OpenShift sandboxed containers Operator                      stable-1.3
security-profiles-operator                    Security Profiles Operator                                   release-alpha-rhel-8
self-node-remediation                         Self Node Remediation Operator                               stable
serverless-operator                           Red Hat OpenShift Serverless                                 stable
service-registry-operator                     Red Hat Integration - Service Registry Operator              2.x
servicemeshoperator                           Red Hat OpenShift Service Mesh                               stable
skupper-operator                              Skupper                                                      alpha
sriov-network-operator                        SR-IOV Network Operator                                      stable
submariner                                    Submariner                                                   stable-0.14
topology-aware-lifecycle-manager              Topology Aware Lifecycle Manager                             stable
vertical-pod-autoscaler                       VerticalPodAutoscaler                                        stable
volsync-product                               VolSync                                                      stable
web-terminal                                  Web Terminal                                                 fast
windows-machine-config-operator               Windows Machine Config Operator                              stable

real  2m51.666s
user  0m24.062s
sys  0m6.355s
$ time oc mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.12 --package=kubernetes-nmstate-operator
NAME                         DISPLAY NAME                 DEFAULT CHANNEL
kubernetes-nmstate-operator  Kubernetes NMState Operator  stable

PACKAGE                      CHANNEL  HEAD
kubernetes-nmstate-operator  4.12     kubernetes-nmstate-operator.4.12.0-202302061702
kubernetes-nmstate-operator  stable   kubernetes-nmstate-operator.4.12.0-202302061702

real  2m20.647s
user  0m22.774s
sys  0m7.225s
$ time oc mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.12 --package=kubernetes-nmstate-operator --channel=4.12
VERSIONS
4.12.0-202301241446
4.12.0-202302061702

real  2m38.125s
user  0m23.130s
sys  0m6.681s
```
