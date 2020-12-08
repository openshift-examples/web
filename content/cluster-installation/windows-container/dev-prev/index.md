---
title: Windows Container DevPreview
linktitle: DevPreview
description: Windows Container DevPreview on AWS or Azure
---
# Windows Container - DevPreview

<center>
![](windows-container.gif)
</center>

Checkout the Video from [Christian Hernandez](https://twitter.com/christianh814)

<center>
<iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/Pa_hiTlcP_w" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

## Installation

<!-- internal docs, Azure: https://docs.google.com/document/d/1fDdrTvQlci9ZNYB_Uli6B7KlvVIfs6Ps_V9l-wEKPr8/edit# -->
<!-- internal docs, AWS: https://docs.google.com/document/d/1dG9WvpwW0D2-f4gnrO2hz2-MXVOqoKGkngzhA_OS-3k/edit# -->

### Prerequisite

 * Create a AWS key pairs with name windows-ssh-key


```bash
cd ~/directory-to-store-cluster-data
docker run -ti -v ~/.aws/:/root/.aws:z -v $(pwd)/:/work:z quay.io/openshift-examples/windows-container-install-helper:latest
cd /work
# Run script, it's not perfect just for me to spinup a OpenShift 4 cluster with a windows worker
aws-create-cluster.sh
```


## Demo applications

### Run powershell.exe webserver

!!! note
    the image size is 2GB! It take some time to pull the image

```bash
oc new-project windows-container
oc label namespace windows-container "openshift.io/run-level=1"

oc create -f https://gist.githubusercontent.com/suhanime/683ee7b5a2f55c11e3a26a4223170582/raw/d893db98944bf615fccfe73e6e4fb19549a362a5/WinWebServer.yaml
```

### Sample APS.NET

```bash
oc new-project windows-container
oc label namespace windows-container "openshift.io/run-level=1"
```

!!! note
    In order to deploy into a different namespace SCC must be disabled in that namespace. This should never be used in production, and any namespace that this has been done to should not be used to run Linux pods.

```yaml hl_lines="31 32 33 34 35"
oc create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: sample-aspnetapp
  name: sample-aspnetapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sample-aspnetapp
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: sample-aspnetapp
    spec:
      containers:
      - image: mcr.microsoft.com/dotnet/framework/samples:aspnetapp
        imagePullPolicy: IfNotPresent
        name: sample-aspnetapp
        ports:
        - containerPort: 80
          protocol: TCP
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      nodeSelector:
        beta.kubernetes.io/os: windows
      tolerations:
      - key: os
        value: Windows
EOF

oc create -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: sample-aspnetapp
  labels:
    app: sample-aspnetapp
spec:
  ports:
    # the port that this service should serve on
  - port: 80
    targetPort: 80
  selector:
    app: sample-aspnetapp
  type: LoadBalancer
EOF

oc expose service/sample-aspnetapp

```

