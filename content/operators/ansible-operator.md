---
title: Ansible Operator
linktitle: Ansible Operator
weight: 12200
description: TBD
render_macros: false
---
## Ansible Operator example

### Resources

* [OperatorSDK](https://github.com/operator-framework/operator-sdk/) \( [Example](https://github.com/operator-framework/operator-sdk/#create-and-deploy-an-app-operator) \)

#### Create first ansible operator

```bash
mkdir sample-operator
cd sample-operator

operator-sdk init \
  --plugins=ansible.sdk.operatorframework.io/v1 \
  --domain=example.com \
  --group=app --version=v1alpha1 --kind=AppService \
  --generate-playbook \
  --generate-role

make docker-build docker-push \
  IMG="quay.io/openshift-examples/ansible-example-operator:latest"

make deploy \
  IMG="quay.io/openshift-examples/ansible-example-operator:latest"

kubectl get pods -n sample-operator-system --watch

kubectl apply -f config/samples/app_v1alpha1_appservice.yaml

kubectl logs -n sample-operator-system \
    -l control-plane=controller-manager -c manager --tail=-1

```

#### Adjust `roles/appservice/tasks/main.yml`

```text
--8<-- "content/operators/ansible-operator-demo/example-tasks.yaml"
```

#### Rebuild and redeploy

```bash
make docker-build docker-push \
  IMG="quay.io/openshift-examples/ansible-example-operator:latest"

make deploy \
  IMG="quay.io/openshift-examples/ansible-example-operator:latest"
```

#### Cleanup

```bash
make undeploy
```
