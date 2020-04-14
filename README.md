# Content of [examples.openshift.pub](examples.openshift.pub) 

![](content/images/logo-black.png)

## Build & Deploy site

### Source-to-Image

via Docker

```
s2i build https://github.com/openshift-examples/web.git \
    quay.io/openshift-examples/ubi8-s2i-mkdocs:latest \
    my-openshift-example
```

via Podman

```bash
s2i build https://github.com/openshift-examples/web.git \
    quay.io/openshift-examples/ubi8-s2i-mkdocs:latest \
    --as-dockerfile my-openshift-example

podman build -t my-openshift-example:latest -f my-openshift-example .
podman run -p 8080:8080 my-openshift-example:latest
```

### OpenShift 

```
oc new-build --name=stage-1-build-static-content \
  quay.io/openshift-examples/ubi8-s2i-mkdocs:latest~https://github.com/openshift-examples/web.git

oc create imagestream stage-2-nginx

oc apply -f - <<EOF
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: stage-2-nginx
spec:
  failedBuildsHistoryLimit: 5
  output:
    to:
      kind: ImageStreamTag
      name: stage-2-nginx:latest
  runPolicy: Serial
  source:
    images:
    - as: null
      from:
        kind: ImageStreamTag
        name: stage-1-build-static-content:latest
      paths:
      - destinationDir: .
        sourcePath: /opt/app-root/src/site/.
    type: Image
  strategy:
    sourceStrategy:
      from:
        kind: DockerImage
        name: registry.redhat.io/rhel8/nginx-116
      incremental: false
      pullSecret:
        name: 12102058-openshift-examples-pull-secret
    type: Source
  successfulBuildsHistoryLimit: 5
  triggers:
  - type: ConfigChange
  - type: "imageChange" 
    imageChange:
      from:
        kind: "ImageStreamTag"
        name: "stage-1-build-static-content:latest"
EOF


oc new-app --name web stage-2-nginx 

# ToDo Route with realdomain:
oc expose svc/web

```


