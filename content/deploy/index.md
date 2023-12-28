---
title: Deployments
linktitle: Deployments
weight: 4100
description: TBD
icon: material/folder-play
---
# Deployments

## Deployment from private registry

Documentation: [Using image pull secrets](https://docs.openshift.com/container-platform/latest/openshift_images/managing_images/using-image-pull-secrets.html)

### Create pull-secret

```bash
oc create secret generic <pull_secret_name> \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson
```

```bash
oc create secret docker-registry <pull_secret_name> \
    --docker-server=<registry_server> \
    --docker-username=<user_name> \
    --docker-password=<password> \
    --docker-email=<email>
```

### Option 1) Link service account to pull secret

```bash
oc secrets link default <pull_secret_name> --for=pull
```

### Option 2) Pod Spec

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
  - name: generic
```


## BusyBox Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
    - name: busybox
      image: busybox
      command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
  restartPolicy: Never
```

## BusyBox Pod with PVC
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-nfs
spec:
  containers:
  - name: busybox-nfs
    image: busybox
    command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
  volumes:
    - persistentVolumeClaim: nfs
  restartPolicy: Never
```


## Simple Deployment

```yaml
oc apply -f - <<EOF
--8<-- "content/deploy/files/simple-deployment.yaml"
EOF
```

## Simple DeploymentConfig
```yaml
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: busybox
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: busybox
    spec:
      containers:
      - image: busybox
        name: busybox
        command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
  triggers:
  - type: ConfigChange
```
## Simple DeploymentConfig with hostpath
```yaml
#
#   oc create serviceaccount hostaccess
#   oc adm policy add-scc-to-user hostaccess -z hostaccess
---
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: rhel-tools
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: rhel-tools
    spec:
      serviceAccountName: hostaccess
      containers:
        - name: rhel-tools
          image: rhel7/rhel-tools
          command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
          volumeMounts:
            - name: host
              mountPath: /host
      volumes:
        - name: host
          hostPath:
            path: /
  triggers:
  - type: ConfigChange

```

## Pod with hostpath

```yaml
#
#   oc create serviceaccount hostaccess
#   oc adm policy add-scc-to-user hostaccess -z hostaccess
---
apiVersion: v1
kind: Pod
metadata:
  name: rhel-tools
spec:
#  serviceAccountName: hostaccess
  containers:
    - name: rhel-tools
      image: rhel7/rhel-tools
      command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
      volumeMounts:
        - name: host
          mountPath: /host
  restartPolicy: Never
  volumes:
    - name: host
      hostPath:
        path: /
```

## S2I playground

```yaml
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
```

## Deployment with limit and request:

```
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: ubi8
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: ubi8
    spec:
      containers:
      - image: ubi8
        name: container-1
        command:
        - /bin/sh
        - "-c"
        - |
          while true ;
            do date;
            sleep 1;
          done;
        resources:
          limits:
            memory: 10Gi
          requests:
            memory: 10Gi
  triggers:
  - type: ConfigChange
```

##### Example

List of allocatable memory:
```bash
$ oc get nodes -o custom-columns=NAME:.metadata.name,MEM-allocatable:.status.allocatable.memory  -l node-role.kubernetes.io/worker
NAME                                 MEM-allocatable
worker-1.rbohne.e2e.bos.redhat.com   15270340Ki
worker-2.rbohne.e2e.bos.redhat.com   15270356Ki
worker-3.rbohne.e2e.bos.redhat.com   15270356Ki
```

!!! note
    This is allocatable memory on the whole host for Pods.
    The amount of allocatable memory do **NOT** include allocated memory of running Pods!


**Request & limit:**

```
resources:
  limits:
    memory: 32Gi
  requests:
    memory: 32Gi
```

**Result:** `0/6 nodes are available: 6 Insufficient memory.`

**Request & limit:**

```
resources:
  limits:
    memory: 10Gi
  requests:
    memory: 10Gi
```

**Result:**

Scale up to 3 Pods: `oc scale --replicas=3 dc/ubi8`

```bash
$ oc get pods -o wide -l deploymentconfig=ubi8
NAME           READY   STATUS    RESTARTS   AGE   IP            NODE                                 NOMINATED NODE   READINESS GATES
ubi8-7-56bqv   1/1     Running   0          19m   10.131.0.18   worker-3.rbohne.e2e.bos.redhat.com   <none>           <none>
ubi8-7-5wlhm   1/1     Running   0          19m   10.128.2.65   worker-2.rbohne.e2e.bos.redhat.com   <none>           <none>
ubi8-7-gdtf2   1/1     Running   0          19m   10.129.2.28   worker-1.rbohne.e2e.bos.redhat.com   <none>           <none>
```