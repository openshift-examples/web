# Ops Container

## DaemonSet

```bash
#
# oc adm new-project --node-selector="" ops-container
# oc project ops-container
# oc adm policy add-scc-to-user privileged -z default
#
# How to do on K8s: https://itnext.io/get-a-shell-to-a-kubernetes-node-9b720a15a4fe
# Or use "oc debug node/..."
oc apply -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ops-container
spec:
  updateStrategy:
    type: OnDelete
  selector:
    matchLabels:
      name: ops-container
  template:
    metadata:
      labels:
        name: ops-container
    spec:
      tolerations:
        - operator: Exists
      hostPID: true
      hostIPC: true
      hostNetwork: true
      hostname: ops
      # nodeSelector:
      #   kubernetes.io/hostname: node3.novalocal
      # nodeName: node3.novalocal
      volumes:
        - name: host
          hostPath:
            path: /
        - name: run
          hostPath:
            path: /run
        - name: log
          hostPath:
            path: /var/log
        - name: localtime
          hostPath:
            path: /etc/localtime
      containers:
        - name: rhel
          image: registry.access.redhat.com/rhel7/support-tools
          command: [ "/bin/sh", "-c", "sleep infinity" ]
          securityContext:
            privileged: true
            runAsUser: 0
          env:
            - name: HOST
              value: "/host"
            - name: NAME
              value: "ops"
            - name: IMAGE
              value: "registry.access.redhat.com/rhel7/support-tools"
          volumeMounts:
            - name: host
              mountPath: /host
            - name: run
              mountPath: /run
            - name: log
              mountPath: /var/log
            - name: localtime
              mountPath: /etc/localtime
EOF
```

## RHEL Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: rhel
spec:
  hostPID: true
  hostIPC: true
  hostNetwork: true
  hostname: toor
  # nodeSelector:
  #   kubernetes.io/hostname: node3.novalocal
  # nodeName: node3.novalocal
  volumes:
    - name: host
      hostPath:
        path: /
    - name: run
      hostPath:
        path: /run
    - name: log
      hostPath:
        path: /var/log
    - name: localtime
      hostPath:
        path: /etc/localtime
  containers:
    - name: rhel
      image: rhel7/rhel-tools
      command: [ "/bin/sh", "-c", "while true ; do date; sleep 1; done;" ]
      securityContext:
        privileged: true
      env:
        - name: HOST
          value: "/host"
        - name: NAME
          value: "toor"
        - name: IMAGE
          value: "rhel/rhel-tools"
      volumeMounts:
        - name: host
          mountPath: /host
        - name: run
          mountPath: /run
        - name: log
          mountPath: /var/log
        - name: localtime
          mountPath: /etc/localtime
  restartPolicy: Never

```