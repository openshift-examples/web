---
title: Terraform
linktitle: Terraform
description: OpenShift Virt & Terraform examples
tags: ['terraform','kubevirt','cnv','ocp-v']
icon: material/terraform
---

# Terraform

This page provides example Terraform configurations for managing virtual machines on OpenShift Virtualization using the [alekc/kubectl](https://registry.terraform.io/providers/alekc/kubectl/latest/docs) provider.

|Component|Version|
|---|---|
|OpenShift|v4.22.3|
|OpenShift Virt|v4.22.2|
|Terraform|v1.12.2|

## Prerequisites

```shell title="Install Terraform on macOS"
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

## Deploy a VM

=== "Download: main.tf"

    ```shell
    curl -L -O {{ page.canonical_url }}main.tf
    ```

=== "main.tf"

    ```hcl
    --8<-- "content/kubevirt/terraform/main.tf"
    ```

```shell title="Initialize and apply"
cp -v $KUBECONFIG kubeconfig-terraform
terraform init
terraform apply
```

??? example "`terraform apply` output"

    ```shell hl_lines="95 108"
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated
    with the following symbols:
      + create

    Terraform will perform the following actions:

      # kubectl_manifest.rhel9_vm will be created
      + resource "kubectl_manifest" "rhel9_vm" {
          + api_version             = "kubevirt.io/v1"
          + apply_only              = false
          + field_manager           = "kubectl"
          + force_conflicts         = false
          + force_new               = false
          + id                      = (known after apply)
          + kind                    = "VirtualMachine"
          + live_manifest_incluster = (sensitive value)
          + live_uid                = (known after apply)
          + name                    = "rhel9"
          + namespace               = "rbohne-kubevirt-terraform"
          + server_side_apply       = false
          + uid                     = (known after apply)
          + upgrade_api_version     = false
          + validate_schema         = true
          + wait_for_rollout        = true
          + yaml_body               = (sensitive value)
          + yaml_body_parsed        = <<-EOT
                apiVersion: kubevirt.io/v1
                kind: VirtualMachine
                metadata:
                  name: rhel9
                  namespace: rbohne-kubevirt-terraform
                spec:
                  dataVolumeTemplates:
                  - metadata:
                      name: rhel9-root
                    spec:
                      sourceRef:
                        kind: DataSource
                        name: rhel9
                        namespace: openshift-virtualization-os-images
                      storage:
                        accessModes:
                        - ReadWriteMany
                        resources:
                          requests:
                            storage: 30Gi
                  runStrategy: Always
                  template:
                    metadata:
                      labels:
                        kubevirt.io/vm: rhel9
                    spec:
                      domain:
                        cpu:
                          cores: 2
                        devices:
                          disks:
                          - bootOrder: 1
                            disk:
                              bus: virtio
                            name: root
                          interfaces:
                          - bridge: {}
                            model: virtio
                            name: coe
                        memory:
                          guest: 4Gi
                        resources:
                          requests:
                            memory: 4Gi
                  networks:
                  - multus:
                      networkName: coe-bridge
                    name: coe
                  volumes:
                  - dataVolume:
                      name: rhel9-root
                    name: root
            EOT
          + yaml_incluster          = (sensitive value)

          + timeouts {
              + create = "20m"
            }

          + wait_for {
              + field {
                  + key        = "status.printableStatus"
                  + value      = "Running"
                  + value_type = "eq"
                }
            }
        }

    Plan: 1 to add, 0 to change, 0 to destroy.

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.

      Enter a value: yes

    kubectl_manifest.rhel9_vm: Creating...
    kubectl_manifest.rhel9_vm: Still creating... [00m10s elapsed]
    kubectl_manifest.rhel9_vm: Still creating... [00m20s elapsed]
    kubectl_manifest.rhel9_vm: Creation complete after 22s [id=/apis/kubevirt.io/v1/namespaces/rbohne-kubevirt-terraform/virtualmachines/rhel9]

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    ```

<iframe width="560" height="315" src="https://www.youtube.com/embed/w9JF6eUKd5A?si=8eWWdinMfHLFZDE9" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>