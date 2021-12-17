---
title: Faketime for your application
linktitle: Faketime (libtaketime)
description: Faketime for your application
tags:
  - time
  - tagB
---

# Faketime for your application

How to inject <https://github.com/wolfcw/libfaketime> into your application deployment.



=== "libfaketime.yaml"

    ```yaml hl_lines="48-51"
    --8<-- "content/deploy/libfaketime.yaml"
    ```

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}content/deploy/libfaketime.yaml
    ```



