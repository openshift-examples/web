# Log Forwarding demo

## Start fluentd to file logging

```yaml
oc new-project fluentd

oc create -f -<<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: fluentd-log
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: managed-nfs-storage
EOF

oc create -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fluentd
  namespace: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  replicas: 1
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
        - name: fluentd
          image: docker.io/fluent/fluentd:v1.3-debian-1
          ports:
            - containerPort: 24224
          volumeMounts:
          - mountPath: /fluentd/log
            name: fluentd-log
      volumes:
      - name: fluentd-log
        persistentVolumeClaim:
          claimName: fluentd-log
EOF


oc create -f <<EOF
apiVersion: v1
kind: Service
metadata:
  name: fluentd
  namespace: fluentd
spec:
  selector:
    app: fluentd
  ports:
    - protocol: TCP
      port: 24224
      targetPort: 24224
EOF
```

### Test fluentd

```bash
$ oc get pods
NAME                       READY   STATUS    RESTARTS   AGE
fluentd-67fb5d89c6-9pvfn   1/1     Running   0          4m1s
$ oc rsh fluentd-67fb5d89c6-9pvfn
$ echo '{"message":"fooobar"}' | fluent-cat debug.log --host fluentd.fluentd.svc.cluster.local  --port 24224
$ grep fooobar /fluentd/log/data.log
2020-10-28T10:42:24+00:00	debug.log	{"message":"fooobar"}
```

## Deploy Cluster Logging

 * Deploy OpenShift Logging Operator
 * Deploy Elastic Search Operator from Red Hat.

```yaml
oc create -f - <<EOF
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  annotations:
    clusterlogging.openshift.io/logforwardingtechpreview: enabled
  name: instance
  namespace: openshift-logging
spec:
  collection:
    logs:
      fluentd: {}
      type: fluentd
  managementState: Managed
EOF
```


## Deploy Log forwarding api - OpenShift 4.5


```yaml
oc create -f - <<EOF
apiVersion: logging.openshift.io/v1alpha1
kind: LogForwarding
metadata:
  name: instance
  namespace: openshift-logging
spec:
  disableDefaultForwarding: true
  outputs:
    - name: fluentd-created-by-user
      type: forward
      endpoint: 'fluentd.fluentd.svc.cluster.local:24224'
  pipelines:
    - name: app-pipeline
      inputSource: logs.app
      outputRefs:
        - fluentd-created-by-user
    - name: infra-pipeline
      inputSource: logs.infra
      outputRefs:
        - fluentd-created-by-user
    - name: clo-default-audit-pipeline
      inputSource: logs.audit
      outputRefs:
        - fluentd-created-by-user
EOF
```

