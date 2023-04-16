---
title: The list problem
linktitle: The list problem
description: The list problem, how to add an element to an existing list
tags:
  - gitops
---

# The list problem

how to add an element to an existing list

## Bootstrap the playground


### Create namespace or use existing one

```bash
oc new-project gitops-list-problem
```

### Build up playground

=== "oc apply -k"

    ```bash
    oc apply -k {{ config.repo_url }}.git/content/gitops/the-list-problem/01-bootstrap/?ref=
    ```

=== "CustomResourceDefinition"

    ```yaml
    --8<-- "content/gitops/the-list-problem/01-bootstrap/CustomResourceDefinition/gitops-examples-openshift-pub.yaml"
    ```


=== "CR"

    ```yaml
    --8<-- "content/gitops/the-list-problem/01-bootstrap/ExamplesOpenShiftPub/test.yaml"
    ```

### The command to rest between tests:

```bash
oc apply --force-conflicts --server-side \
  -k {{ config.repo_url }}.git/content/gitops/the-list-problem/01-bootstrap/ExamplesOpenShiftPub/
```

## ❌ Test 1) oc apply --server-side


```bash
oc apply --server-side -f - <<EOF
apiVersion: examples.openshift.pub/v1
kind: ExamplesOpenShiftPub
metadata:
  name: test
spec:
  list:
  - second-element
EOF
```


### Result:

```yaml
apiVersion: examples.openshift.pub/v1
kind: ExamplesOpenShiftPub
metadata:
  name: test
spec:
  list:
  - second-element
```

## ✅ Test 2) oc patch --type=json

```bash
oc patch eop/test --type=json \
  -p '[{"op":"add", "path":"/spec/list/-1","value":"second-element"}]'
```

* `/spec/list/-1` add element to the end
* `/spec/list/0` add element at the beginning

### Result:

```yaml
apiVersion: examples.openshift.pub/v1
kind: ExamplesOpenShiftPub
metadata:
  name: test
spec:
  list:
  - first-element
  - second-element
```


## ❌ Test 3) oc patch --type=merge

```bash
oc patch eop/test --type=merge \
  -p '{"spec":{"list":["second-element"]}}'
```

### Result:

```yaml
apiVersion: examples.openshift.pub/v1
kind: ExamplesOpenShiftPub
metadata:
  name: test
spec:
  list:
  - second-element
```

## ❌ Test 4) kustomize & patchesJSON6902

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

patchesJSON6902:
- target:
    group: examples.openshift.pub
    version: v1
    kind: ExamplesOpenShiftPub
    name: test
  patch: |-
    - op: add
      path: /spec/list/-1
      value: "second-element"

```

=> You can only patch objects, they are handled via kustomize.

### Result:

```bash
$ kustomize build test-04-kustomize/
$
```

## ❌ Test 5) argocd serversideapply

```bash
oc create -n openshift-gitops 

