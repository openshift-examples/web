---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sriov-eno4
  namespace: rbohne-sriov-test
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: sriov-eno4
  template:
    metadata:
      annotations:
        k8s.v1.cni.cncf.io/networks: storm5-rbohne-sriov-test-eno4
      labels:
        app: sriov-eno4
    spec:
      serviceAccountName: privileged
      volumes:
      - name: hugepage
        emptyDir:
          medium: HugePages
      containers:
      #
      #- image: default-route-openshift-image-registry.apps.ocp5.stormshift.coe.muc.redhat.com/openshift/tools:latest
      - image: registry.redhat.io/openshift4/dpdk-base-rhel8:v4.9.5-2
        resources:
          limits:
            openshift.io/storm5eno3: "1"
            memory: "1Gi"
            cpu: "4"
            hugepages-1Gi: "1Gi"
          requests:
            openshift.io/storm5eno3: "1"
            memory: "1Gi"
            cpu: "4"
            hugepages-1Gi: "1Gi"
        securityContext:
          runAsUser: 0
          capabilities:
            # add: ["IPC_LOCK","SYS_RESOURCE","NET_RAW"]
            add: ["IPC_LOCK"]
        name: sriov-eno4
        volumeMounts:
        - mountPath: /dev/hugepages
          name: hugepage
        command:
          - /bin/bash
          - -c
          - |
              dnf install -y which

              dpdk-devbind.py --status-dev net

              dpdk-hugepages.py -s

              sleep infinity
  triggers:
  - type: ConfigChange
