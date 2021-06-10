---
title: Java/JAR Deployment
linktitle: Java/JAR
description: Some examples howto deploy a JAR
tags:
  - java
  - jar
  - deploy
---

# Java/JAR Deployment

## Multi-stage build


### Build of container image

Source & Containerfile is available at [openshift-quickstarts/undertow-servlet](https://github.com/openshift-examples/openshift-quickstarts/blob/master/undertow-servlet/Containerfile.initContainer)

=== "Containerfile"

    ```Dockerfile
    FROM registry.access.redhat.com/ubi8/openjdk-11:latest as builder
    USER root
    COPY ./ /tmp/src
    RUN chown -R 185:0 /tmp/src
    USER 185
    RUN /usr/local/s2i/assemble

    FROM registry.access.redhat.com/ubi8/openjdk-11-runtime
    COPY --from=builder /deployments /deployments

    CMD ["java","-jar","/deployments/undertow-servlet.jar"]
    ```

### Deployment

=== "deployment-multi-stage.yaml"

    ```yaml
    --8<-- "content/deploy/jar/deployment-multi-stage.yaml"
    ```

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}deployment-multi-stage.yaml
    ```


## Unconventional: copy via initContainer into runtime

### Build of initContainer image

Source & Containerfile is available at [openshift-quickstarts/undertow-servlet](https://github.com/openshift-examples/openshift-quickstarts/blob/master/undertow-servlet/Containerfile.initContainer)

=== "Containerfile"

    ```Dockerfile
    FROM registry.access.redhat.com/ubi8/openjdk-11:latest as builder
    USER root
    COPY ./ /tmp/src
    RUN chown -R 185:0 /tmp/src
    USER 185
    RUN /usr/local/s2i/assemble

    FROM registry.access.redhat.com/ubi8/ubi-micro
    COPY --from=builder /deployments /deployments
    CMD echo "Please don't start..."
    ```

### Deployment

=== "deployment-init-container.yaml"

    ```yaml hl_lines="21-32"
    --8<-- "content/deploy/jar/deployment-init-container.yaml"
    ```

=== "OC"

    ```
    oc apply -f {{ page.canonical_url }}deployment-init-container.yaml
    ```

