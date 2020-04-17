## anyuid example 

### Create project and service account
```bash
oc new-project anyuid-demo
oc create sa anyuid
```

### Allow service account to use scc anyuid

#### prior 4.3.8

```bash
oc adm policy add-scc-to-user -n anyuid-demo -z anyuid anyuid 
```

#### past 4.3.8

Use [Role-based access to Security Context Constraints](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html#role-based-access-to-ssc_configuring-internal-oauth).

```bash
oc create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scc-anyuid
  namespace: anyuid-demo
rules:
- apiGroups:
  - security.openshift.io 
  resourceNames:
  - anyuid
  resources:
  - securitycontextconstraints 
  verbs: 
  - use
EOF

oc create -f - <<EOF
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sa-to-scc-anyuid
  namespace: anyuid-demo
subjects:
  - kind: ServiceAccount
    name: anyuid
roleRef:
  kind: Role
  name: scc-anyuid
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Deploy 

#### without-anyuid
```bash
oc apply -f - <<EOF
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: without-anyuid
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: without-anyuid
    spec:
      containers:
      - image: ubi8/ubi-minimal
        name: container
        command: 
          - "/bin/sh"
          - "-c"
          - | 
            while true ; do 
              date; 
              echo -n "id: "
              id;
              sleep 1; 
            done;
  triggers:
  - type: ConfigChange
EOF
```

#### with-anyuid

!!! note
    Important is the `serviceAccount` and `serviceAccountName`!

```bash
oc apply -f - <<EOF
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: with-anyuid
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        deploymentconfig: with-anyuid
    spec:
      serviceAccount: anyuid
      serviceAccountName: anyuid
      containers:
      - image: ubi8/ubi-minimal
        name: container
        command: 
          - "/bin/sh"
          - "-c"
          - | 
            while true ; do 
              date; 
              echo -n "id: "
              id;
              sleep 1; 
            done;
  triggers:
  - type: ConfigChange
EOF
```

### Result:

```bash
$ oc get pods -l deployment -o "custom-columns=NAME:.metadata.name,SCC:.metadata.annotations.openshift\.io/scc,SERVICEACCOUNT:.spec.serviceAccountName"
NAME                     SCC          SERVICEACCOUNT
with-anyuid-1-gxczf      anyuid       anyuid
without-anyuid-1-fdhfb   restricted   default

$ oc logs  dc/without-anyuid  | tail -2
Fri Apr 17 10:11:14 UTC 2020
id: uid=1000540000(1000540000) gid=0(root) groups=0(root),1000540000
$ oc logs  dc/with-anyuid  | tail -2
Fri Apr 17 10:11:18 UTC 2020
id: uid=0(root) gid=0(root) groups=0(root)
```
