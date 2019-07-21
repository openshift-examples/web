# Example for simple pods
## Anyuid Example

```yaml
oc new-project anyuid-demo
oc create sa anyuid
# Need cluster-admin privileges
oc adm policy add-scc-to-user -n anyuid-demo -z anyuid anyuid 

cat <<EOF | oc apply -f -
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: busybox-without-anyuid
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: busybox-without-anyuid
    spec:
      containers:
      - image: busybox
        name: busybox
        command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
  triggers:
  - type: ConfigChange
EOF

cat <<EOF | oc apply -f -
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: busybox-with-anyuid
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: busybox-with-anyuid
    spec:
      securityContext: {}
      serviceAccount: anyuid
      serviceAccountName: anyuid
      containers:
      - image: busybox
        name: busybox
        command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
  triggers:
  - type: ConfigChange
EOF
```

### Check SCC

```sh
$ oc get pods -o "custom-columns=NAME:.metadata.name,SCC:.metadata.annotations.openshift\.io/scc,SERVICEACCOUNT:.spec.serviceAccountName"
NAME                             SCC          SERVICEACCOUNT
busybox-with-anyuid-1-m98pb      anyuid       anyuid
busybox-without-anyuid-2-vrmc5   restricted   default

$ oc get pods -o "custom-columns=NAME:.metadata.name,SCC:.metadata.annotations.openshift\.io/scc,SERVICEACCOUNT:.spec.serviceAccountName"

$ oc rsh $(oc get pods -o name -l deploymentconfig=busybox-without-anyuid) id
uid=1000140000 gid=0(root) groups=1000140000uid=1000140000 gid=0(root) groups=1000140000

$ oc rsh $(oc get pods -o name -l deploymentconfig=busybox-with-anyuid) id
uid=0(root) gid=0(root) groups=10(wheel)
```

## Run a s2i build pod to play around:

```yaml
# Build & Deploy
echo << EOF | oc apply -f -
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: builder-test
---
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    build: builder-test
  name: builder-test
spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: builder-test:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    dockerfile: "FROM rhscl/s2i-base-rhel7:latest \nENTRYPOINT bash\n"
    type: Dockerfile
  strategy:
    dockerStrategy:
      from:
        kind: DockerImage
        name: registry.redhat.io/rhscl/s2i-base-rhel7:latest
    type: Docker
  successfulBuildsHistoryLimit: 5
---
apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  labels:
    app: builder-test
  name: builder-test
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    app: builder-test
    deploymentconfig: builder-test
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: builder-test
        deploymentconfig: builder-test
    spec:
      containers:
      - image: builder-test:latest
        imagePullPolicy: Always
        name: builder-test
        command:
        - /bin/sh
        - -c
        - while true ; do date; sleep 1; done;
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
  test: false
  triggers:
  - type: ConfigChange
  - imageChangeParams:
      automatic: true
      containerNames:
      - builder-test
      from:
        kind: ImageStreamTag
        name: builder-test:latest
        namespace: anyuid
    type: ImageChange
EOF
```