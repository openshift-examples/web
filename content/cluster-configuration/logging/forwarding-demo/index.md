---
title: Audit Log Forwarding to Rsyslog
linktitle: Audit Log Forwarding
description: Forward and filter OpenShift audit logs to a remote rsyslog server using ClusterLogForwarder
tags: ['logging', 'audit', 'v4.22']
---
# Audit Log Forwarding to Rsyslog

This example demonstrates how to forward Kubernetes API audit logs from an
OpenShift cluster to an external rsyslog server using the `ClusterLogForwarder`
resource. The filter is configured to capture only KubeVirt-related API
activity (`VirtualMachine`, `VirtualMachineInstance`,
`VirtualMachineInstanceMigration`), keeping the log volume focused and
manageable.

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.22.5|
|OpenShift Logging|v6.6.0|

Documentation: [Chapter 2. Configuring log forwarding](https://docs.redhat.com/en/documentation/red_hat_openshift_logging/6.6/html/configuring_logging/configuring-log-forwarding)

## Start rsyslog to file logging

First, deploy a simple rsyslog instance inside the cluster that receives
forwarded logs over TCP and writes them to persistent storage.

### Create new project

=== "OC"

    ```shell
    oc new-project rsyslog
    ```

### Deploy rsyslog

=== "Download: deploy-rsyslog.yaml"

    ```shell
    curl -L -O {{ page.canonical_url }}deploy-rsyslog.yaml
    ```

=== "deploy-rsyslog.yaml"

    ```yaml
    --8<-- "content/cluster-configuration/logging/forwarding-demo/deploy-rsyslog.yaml"
    ```

=== "OC"

    ```shell
    oc apply -f {{ page.canonical_url }}deploy-rsyslog.yaml
    ```

The deployment includes three containers:

- **rsyslog** — listens on TCP port 24224 and writes all received messages to `/log/all.log` as well as per-host/program files under `/log/`.
- **jq** — tails the KubeVirt audit log and pretty-prints each entry as a single line with verb, duration, status code, request URI, and user.
- **cdt** — builds [cluster-debug-tools](https://github.com/openshift/cluster-debug-tools) for additional troubleshooting.

### Test rsyslog

Login into the pod:

```shell
oc rsh deployment/rsyslog
```

Send a test message and verify:

```shell
logger --tcp --port 24224 --server localhost "test message from rsyslog"
cat /log/all.log
```

## Configure Cluster Logging

Install the OpenShift Logging Operator from OperatorHub before proceeding.
The operator manages the `ClusterLogForwarder` custom resource used in the
next step.

### Create ServiceAccount and RBAC

Audit log collection requires a dedicated service account with the
`collect-audit-logs` cluster role. Without this binding, the collector pods
will not have permission to read the node-level audit log files:

```shell
oc create sa collector -n openshift-logging
oc adm policy add-cluster-role-to-user collect-audit-logs \
  -z collector -n openshift-logging
```

## Deploy Log forwarding API

### Forward audit logs to rsyslog

The `ClusterLogForwarder` below creates a pipeline that sends audit logs to
the rsyslog service. A `kubeAPIAudit` filter limits the output to metadata-level
events for KubeVirt resources, dropping everything else:

```yaml title="ClusterLogForwarder"
oc create -f - <<EOF
apiVersion: observability.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: audit-to-rsyslog
  namespace: openshift-logging
spec:
  serviceAccount:
    name: collector
  outputs:
    - name: rsyslog-server
      type: syslog
      syslog:
        url: 'tcp://rsyslog.rsyslog.svc.cluster.local:24224'
        rfc: RFC5424
  pipelines:
    - name: audit-to-rsyslog
      inputRefs:
        - audit
      filterRefs:
        - only-virt
      outputRefs:
        - rsyslog-server
  filters:
    - name: only-virt
      type: kubeAPIAudit
      kubeAPIAudit:
        omitStages:
          - "RequestReceived"
        rules:
          - level: Metadata
            resources:
            - group: "kubevirt.io"
              resources: ["virtualmachines","virtualmachineinstances","virtualmachineinstancemigrations"]
          - level: None
EOF
```

## Create a Virtual Machine and view the audit logs

Once the forwarding pipeline is active, create a VirtualMachine through the
OpenShift console or CLI. The jq sidecar in the rsyslog pod formats the
incoming audit events into a compact, human-readable stream:

```shell
oc logs -f -n rsyslog -c jq deployment/rsyslog
```

```log
09:25:35 [CREATE][    90.681ms] [201] /apis/kubevirt.io/v1/namespaces/rbohne-vms/virtualmachines [rbohne@redhat.com-admin]
09:26:30 [CREATE][    67.071ms] [201] /apis/kubevirt.io/v1/namespaces/rbohne-vms/virtualmachineinstances [system:serviceaccount:openshift-cnv:kubevirt-controller]
```

<iframe width="560" height="315" src="https://www.youtube.com/embed/X9u5-mC3S-o?si=BqFtvNmejHuINgCz" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
