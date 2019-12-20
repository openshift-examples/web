---
description: Work-in-progress
---

# Liveness probe

```yaml
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: liveness-probe
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      name: liveness-probe
      labels:
        app: liveness-probe
    spec:
      # only supports always
      # restartPolicy: Always
      initContainers:
      - name: initcontainer
        image:  quay.io/openshift-examples/gitlab-runner:latest
        command: [ "/bin/sh", "-c", "sleep 1; echo init done" ]
      containers:
      - name: container-runner
        image:  quay.io/openshift-examples/gitlab-runner:latest
        command: 
        - /bin/sh
        - -c
        - |
          counter=0; while true ; do echo "$counter : $(date)";sleep 1 ; counter=$((counter+1)) ; done;
      - name: container-crashes
        image:  quay.io/openshift-examples/gitlab-runner:latest
        command:
        - /bin/sh
        - -c
        - |
          counter=0; while true ; do echo "$counter : $(date)";sleep 1 ; counter=$((counter+1)) ; done;
        startupProbe:
          exec:
            command:
            - /usr/bin/bash
            - -x
            - -c
            - |
              false       
        livenessProbe:
          exec:
            command:
            - /usr/bin/bash
            - -x
            - -c
            - |
              false
          initialDelaySeconds: 10
          periodSeconds: 5
  triggers:
  - type: ConfigChange
```

