---
title: Node Health Check
linktitle: Node Health Check
description: OpenShift Virtualization - Fencing and VM High Availability Guide
tags: ["kubevirt","ocp-v","cnv"]
---
# Node Health Check

## Resources

* [OpenShift Virtualization - Fencing and VM High Availability Guide](https://access.redhat.com/articles/7057929)

## Installation & configuration

* Install Operator "Node Health Check Operator"

### Start operator for worker nodes

``` { .yaml .annotate }
apiVersion: remediation.medik8s.io/v1alpha1
kind: NodeHealthCheck
metadata:
  name: worker-availability
spec:
  minHealthy: 51%
  remediationTemplate:
    apiVersion: self-node-remediation.medik8s.io/v1alpha1
    kind: SelfNodeRemediationTemplate
    name: self-node-remediation-automatic-strategy-template
    namespace: openshift-workload-availability
  selector:
    matchExpressions:
      - key: node-role.kubernetes.io/worker
        operator: Exists
        values: []
  unhealthyConditions:
    - duration: 1s # (1)!
      status: 'False'
      type: Ready
    - duration: 1s # (2)!
      status: Unknown
      type: Ready
```

1. Change the seconds to achieve the fasted VM recovery, according to [OpenShift Virtualization - Fencing and VM High Availability Guide](https://access.redhat.com/articles/7057929#test-results-9)
2. Change the seconds to achieve the fasted VM recovery, according to [OpenShift Virtualization - Fencing and VM High Availability Guide](https://access.redhat.com/articles/7057929#test-results-9)

### Update `self-node-remediation-automatic-strategy-template`

``` { .yaml .hl_lines="13" .annotate }
apiVersion: self-node-remediation.medik8s.io/v1alpha1
kind: SelfNodeRemediationTemplate
metadata:
  annotations:
    remediation.medik8s.io/multiple-templates-support: "true"
  labels:
    remediation.medik8s.io/default-template: "true"
  name: self-node-remediation-automatic-strategy-template
  namespace: openshift-workload-availability
spec:
  template:
    spec:
      remediationStrategy: OutOfServiceTaint # (1)!
```

1. Default is "Automatic", but I want a predictable behavor. [Offical documentation](https://docs.redhat.com/en/documentation/workload_availability_for_red_hat_openshift/23.2/html-single/remediation_fencing_and_maintenance/index#about-self-node-remediation-operator_self-node-remediation-operator-remediate-nodes)

    ```bash
    $ oc explain SelfNodeRemediationTemplate.spec.template.spec.remediationStrategy
    GROUP:      self-node-remediation.medik8s.io
    KIND:       SelfNodeRemediationTemplate
    VERSION:    v1alpha1

    FIELD: remediationStrategy <string>

    DESCRIPTION:
        RemediationStrategy is the remediation method for unhealthy nodes.
        Currently, it could be either "Automatic", "OutOfServiceTaint" or
        "ResourceDeletion".
        ResourceDeletion will iterate over all pods and VolumeAttachment related to
        the unhealthy node and delete them.
        OutOfServiceTaint will add the out-of-service taint which is a new
        well-known taint "node.kubernetes.io/out-of-service"
        that enables automatic deletion of pv-attached pods on failed nodes,
        "out-of-service" taint is only supported on clusters with k8s version 1.26+
        or OCP/OKD version 4.13+.
        Automatic will choose the most appropriate strategy during runtime.
    ```
