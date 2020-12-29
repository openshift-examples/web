---
title: Build examples
linktitle: Examples
weight: 5100
description: TBD
tags:
  - build
---
# Build examples

## Simple Docker build

```yaml
# oc create is simple-docker-build
oc apply -f - <<EOF
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: simple-docker-build
spec:
  lookupPolicy:
    local: false
EOF

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: simple-docker-build
  labels:
    name: simple-docker-build
spec:
  triggers:
    - type: ConfigChange
  source:
    contextDir: "simple-docker-build/"
    type: Git
    git:
      uri: 'https://github.com/openshift-examples/container-build.git'
  strategy:
    type: Docker
  output:
    to:
      kind: ImageStreamTag
      name: 'simple-docker-build:latest'
EOF
```

## Simple Container build

```yaml hl_lines="20 21"
oc create is simple-container-build

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: simple-container-build
  labels:
    name: simple-container-build
spec:
  triggers:
    - type: ConfigChange
  source:
    contextDir: "simple-container-build/"
    type: Git
    git:
      uri: 'https://github.com/openshift-examples/container-build.git'
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: "Containerfile"
  output:
    to:
      kind: ImageStreamTag
      name: 'simple-container-build:latest'
EOF
```

## Simple context dir

```yaml hl_lines="14"
oc create is simple-context-dir

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: simple-context-dir
  labels:
    name: simple-context-dir
spec:
  triggers:
    - type: ConfigChange
  source:
    contextDir: "simple-context-dir/"
    type: Git
    git:
      uri: 'https://github.com/openshift-examples/container-build.git'
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: "Containerfile"
  output:
    to:
      kind: ImageStreamTag
      name: 'simple-context-dir:latest'
EOF
```


## Complex context dir

```yaml hl_lines="14 20 21"
oc create is complex-context-dir

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: complex-context-dir
  labels:
    name: complex-context-dir
spec:
  triggers:
    - type: ConfigChange
  source:
    contextDir: "complex-context-dir/"
    type: Git
    git:
      uri: 'https://github.com/openshift-examples/container-build.git'
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: "containerfiles/Containerfile"
  output:
    to:
      kind: ImageStreamTag
      name: 'complex-context-dir:latest'
EOF
```

## Multi-stage - builder & runner

** Nothing special at BuildConfig, checkout the Containerfile: **

```Dockerfile hl_lines="1 12"
FROM centos:8 AS builder

RUN yum groupinstall -y 'Development Tools'

RUN curl -L -O https://bird.network.cz/download/bird-1.6.8.tar.gz && \
    tar xzf bird-1.6.8.tar.gz && \
    cd bird-1.6.8 && \
    ./configure --disable-client --prefix=/opt/bird-1.6.8 && \
    make install


FROM registry.access.redhat.com/ubi8/ubi-minimal AS runner
COPY --from=builder /opt/bird-1.6.8 /opt/bird-1.6.8
ENTRYPOINT ["/opt/bird-1.6.8/sbin/bird", "-f"]
```

**BuildConfig**
```yaml
oc create is multi-stage

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: multi-stage
  labels:
    name: multi-stage
spec:
  triggers:
    - type: ConfigChange
  source:
    contextDir: "multi-stage/"
    type: Git
    git:
      uri: 'https://github.com/openshift-examples/container-build.git'
  strategy:
    type: Docker
    dockerStrategy:
      dockerfilePath: "Containerfile"
  output:
    to:
      kind: ImageStreamTag
      name: 'multi-stage:latest'
EOF
```

## Build and push to quay

#### Create push-secret

```yaml
oc create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: openshift-examples-openshift-push-demo-pull-secret
data:
  .dockerconfigjson: xxxxx
type: kubernetes.io/dockerconfigjson
EOF
```

#### Create build config

```bash
oc new-build --name=simple-http-server \
  --push-secret='openshift-examples-openshift-push-demo-pull-secret' \
  --to-docker=true \
  --to="quay.io/openshift-examples/simple-http-server:dev" \
  https://github.com/openshift-examples/simple-http-server.git
```

## Custom build with Buildah


## Add git config

[OpenShift 3.11 documenation](https://docs.openshift.com/container-platform/3.11/dev_guide/builds/build_inputs.html#source-secrets-gitconfig-file-secured)

Create `/tmp/gitconfig`

```text
[http]
    sslVerify = false
# Just for information:
[core]
    sshCommand = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
```

Run commands: \( Create secret & add `--source-secret=build` to new-build \)

```bash
oc create secret generic build --from-file=.gitconfig=/tmp/gitconfig \
    --from-file=ssh-privatekey=/tmp/github_rsa \
    --type=kubernetes.io/ssh-auth

oc new-build registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift~git@github.com:rbo/chaos-professor.git --source-secret=build --env BUILD_LOGLEVEL=5

# If you like, create app
oc new-app chaos-professor
```