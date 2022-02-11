---
title: Faketime for your application
linktitle: Faketime (libtaketime)
description: Faketime for your application
tags:
  - time
  - tagB
---

# Faketime for your application

How to inject <https://github.com/wolfcw/libfaketime> into your application deployment or you use the [Time Machine Operator](https://catalog.redhat.com/software/operators/detail/5e98727a6c5dcb34dfbb19e3)

=== "libfaketime.yaml"

    ```yaml hl_lines="48-51"
    --8<-- "content/deploy/libfaketime.yaml"
    ```

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}content/deploy/libfaketime.yaml
    ```



