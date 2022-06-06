---
title: Pod Autoscaling
linktitle: Pod Autoscaling
weight: 6300
description: About the HorizontalPodAutoscaler
tags:
    - autoscaling
---
# POD Autoscaling

## Deploy Pod Autoscaling exmaple with Chaos Professor

=== "OC"

    ```
    oc process -f {{ page.canonical_url }}pod-autoscaling-template.yaml | oc apply -f -
    ```

=== "pod-autoscaling-template.yaml"

    ```yaml
    --8<-- "content/deploy/autoscaling/pod-autoscaling-template.yaml"
    ```

## Test autoscaling

```text
# Only 4fun
ab 'http://choas-professor-omd.paas.osp.consol.de/chaos/heapheap?size=500&time=10000'
ab 'http://choas-professor-omd.paas.osp.consol.de/chaos/cpu?threads=100&keepAlive=20000'
ab -c 10 -n 100 'http://choas-professor-omd.paas.osp.consol.de/chaos/cpu?threads=100&keepAlive=200'
```

## Delete all

```text
oc get all -o name | xargs -n1  oc delete
oc delete hpa/choas-professor
```

