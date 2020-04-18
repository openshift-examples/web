# Content of [examples.openshift.pub](https://examples.openshift.pub/) 

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

# Create pull secret 
#  https://access.redhat.com/terms-based-registry/

oc create -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: 12102058-openshift-examples-pull-secret
data:
  .dockerconfigjson: xxxxx
type: kubernetes.io/dockerconfigjson
EOF

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

oc expose svc/web \
  --hostname="examples.openshift.pub" \
  --name="examples-openshift-pub" 

# create cname elb.6923.rh-us-east-1.openshiftapps.com.

oc apply -f https://raw.githubusercontent.com/rbo/openshift-acme/respect-range-limits/deploy/single-namespace/serviceaccount.yaml
oc apply -f https://raw.githubusercontent.com/rbo/openshift-acme/respect-range-limits/deploy/single-namespace/role.yaml
oc apply -f https://raw.githubusercontent.com/rbo/openshift-acme/respect-range-limits/deploy/single-namespace/issuer-letsencrypt-staging.yaml
oc create rolebinding openshift-acme --role=openshift-acme --serviceaccount="$( oc project -q ):openshift-acme" --dry-run -o yaml | oc apply -f -
oc apply -f - <<EOF
kind: Deployment
apiVersion: apps/v1
metadata:
  name: openshift-acme
  labels:
    app: openshift-acme
spec:
  selector:
    matchLabels:
      app: openshift-acme
  replicas: 2
  strategy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: openshift-acme
    spec:
      serviceAccountName: openshift-acme
      containers:
      - name: openshift-acme
        image: quay.io/rbo/openshift-acme-controller:respect-range-limits
        imagePullPolicy: Always
        args:
        - --exposer-image=quay.io/rbo/openshift-acme-exposer:respect-range-limits
        - --loglevel=4
        - --namespace=openshiftanwender
        - --namespace=\$(CURRENT_NAMESPACE)
        env:
        - name: CURRENT_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
EOF

oc annotate route/examples-openshift-pub kubernetes.io/tls-acme=true

# Disable cookies
oc annotate route/examples-openshift-pub haproxy.router.openshift.io/disable_cookies=true


```


