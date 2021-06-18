---
title: Debug receiver
linktitle: Debug receiver
description: Debug receiver
tags:
  - alertmanager
  - prometheus
  - debug
  - monitoring
---

# Debug receiver

## Deployment

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}deployment.yaml
    ```

=== "deployment.yaml"

    ```yaml
    --8<-- "content/cluster-configuration/monitoring/alertmanager/debug-receiver/deployment.yaml"
    ```



## Configure alertmanager


Administrator -> Cluster Settings -> Global configuration -> Alertmanager -> Create Receiver

![](receiver-config.png)