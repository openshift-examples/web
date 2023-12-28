---
title: OpenShift Virt Template example
linktitle: VM Templates
description: Virtual Machine Templates in OpenShift Virtualization
tags: ['cnv', 'kubevirt', 'template', 'ocp-v']
---

# Virtual Machine Templates in OpenShift Virtualization

1) First create our own virtual machine image template.
2) Upload the image into a PVC in namespace openshift-virtualization-os-images

    ```bash
    oc project openshift-virtualization-os-images
    virtctl image-upload pvc remote-mgmt-supporter-20231211 --size 30Gi --storage-class coe-netapp-nas --image-path remote-mgmt-supporter-20231211.qcow
    ```

3) Create DataSource to the new PVC

    === "datasource.yaml"

        ```yaml
        --8<-- "content/kubevirt/template/datasource.yaml"
        ```

    === "Download"

        ```
        curl -L -O {{ page.canonical_url }}datasource.yaml
        ```
