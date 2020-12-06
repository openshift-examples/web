---
title: Gitlab Runner
linktitle: Gitlab Runner
weight: 8300
description: TBD
---
# Gitlab Runner

Gitlab runner image based on ubi: [https://quay.io/repository/openshift-examples/gitlab-runner](https://quay.io/repository/openshift-examples/gitlab-runner)

[![Docker Repository on Quay](https://quay.io/repository/openshift-examples/gitlab-runner/status)](https://quay.io/repository/openshift-examples/gitlab-runner)

## Deploy the runner

```text
oc new-project gitlab-runner

oc create sa gitlab-runner
oc adm policy add-role-to-user edit -z gitlab-runner

# Create empty secret gitlab-runner-config
oc create secret generic gitlab-runner-config \
    --from-literal=config.toml=""

# Create secret for registration gitlab-runner-register
oc create secret generic gitlab-runner-register \
    --from-literal=REGISTRATION_TOKEN=xL6C6HEg2CFdXS3rM_BZ \
    --from-literal=CI_SERVER_URL=https://gitlab.com/ \
    --from-literal=RUNNER_EXECUTOR=kubernetes \
    --from-literal=RUNNER_TAG_LIST=ocp
```

Apply deployment config

```yaml
oc create -f - <<EOF
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: gitlab-runner
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      name: gitlab-runner
      labels:
        app: gitlab-runner
    spec:
      serviceAccount: gitlab-runner
      containers:
      - name: run
        image:  quay.io/openshift-examples/gitlab-runner:latest
        command:
          - /usr/bin/bash
          - -x
          - -c
          - |
            # Register
            cp -v /gitlab-runner-config/config.toml $HOME/.gitlab-runner/config.toml

            gitlab-runner unregister --all-runners
            # unregister do not update config.toml if unregister fail.
            rm $HOME/.gitlab-runner/config.*

            gitlab-runner register --non-interactive

            # Update secret
            oc create secret generic gitlab-runner-config  --from-file=config.toml=$HOME/.gitlab-runner/config.toml --dry-run -o yaml | oc apply -f -

            gitlab-runner run
        volumeMounts:
        - name: gitlab-runner-config
          mountPath: "/gitlab-runner-config"
          readOnly: true
        env:
        - name: KUBERNETES_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        envFrom:
        - secretRef:
            name: gitlab-runner-register
        livenessProbe:
          exec:
            command:
            - /usr/bin/bash
            - -x
            - -c
            - |
              # gitlab-runner verify wont work with $CI_SERVER_URL
              unset CI_SERVER_URL
              gitlab-runner verify
          initialDelaySeconds: 10
          periodSeconds: 5
      volumes:
      - name: gitlab-runner-register
        secret:
          secretName: gitlab-runner-register
      - name: gitlab-runner-config
        secret:
          secretName: gitlab-runner-config
  triggers:
  - type: ConfigChange
EOF
```

## Build gitlab-runner image

```text
git clone https://github.com/rbo/openshift-examples.git
cd openshift-examples/workload/gitlab-runner/
podman build -t gitlab-runer .
```

Checkout the [Dockerfile](https://github.com/rbo/openshift-examples/blob/master/workload/gitlab-runner/Dockerfile) for more details.

## Notes

* `gitlab-runner verify` don't work with env variable `CI_SERVER_URL`, know issue: [https://gitlab.com/gitlab-org/gitlab-runner/issues/3904](https://gitlab.com/gitlab-org/gitlab-runner/issues/3904)
* `gitlab-runner run` won't die in case of errors
* Overall it looks like gitlab-runner is not build to run inside a container, but it work.

