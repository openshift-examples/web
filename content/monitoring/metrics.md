# Metrics

## List metrics of a node or pod,...
```

$ oc adm top pod
NAME                              CPU(cores)   MEMORY(bytes)
router-default-7469c545dd-d795m   2m           31Mi
router-default-7469c545dd-q9zrz   2m           32Mi

$ oc adm top node
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
compute-0   131m         8%     920Mi           13%
compute-1   139m         9%     981Mi           14%
compute-2   251m         16%    2135Mi          31%
master-0    794m         22%    3311Mi          22%
master-1    1199m        34%    4556Mi          30%
master-2    885m         25%    4669Mi          31%

```

## Fetch Metrics API inside a POD

```bash
oc create serviceaccount viewer
oc policy add-role-to-user view -z viewer
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: cli
  name: cli
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cli
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: cli
    spec:
      serviceAccount: viewer
      serviceAccountName: viewer
      containers:
      - image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
        imagePullPolicy: Always
        name: cli
        # command: ["/usr/bin/sleep","infinity"]
        command:
          - /usr/bin/sh
          - -c
          - |
            while true; do
              date;
              echo "====== OC ======"
              oc adm top pod
              echo "====== cURL ====="
              curl -s --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
                --header "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" \
                https://kubernetes.default.svc.cluster.local/apis/metrics.k8s.io/v1beta1/namespaces/$KUBERNETES_NAMESPACE/pods ;
              sleep 5;
            done
        # https://access.redhat.com/solutions/5175931
        env:
          - name: HOME
            value: /tmp
          - name: KUBERNETES_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
```

