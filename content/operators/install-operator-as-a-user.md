---
title: Install Operator as a User - WiP
linktitle: Install Operator as a User - WiP
weight: 12400
description: TBD
render_macros: false
---
# WIP: Install Operator as a User

Official documentation: [https://docs.openshift.com/container-platform/4.3/operators/olm-creating-policy.html](https://docs.openshift.com/container-platform/4.3/operators/olm-creating-policy.html)

## Setup htpasswd auth \(Optional\)

### Create htpasswd secret

```text
oc create -f - <<EOF
apiVersion: v1
data:
  htpasswd: "$( (htpasswd -nb admin 'r3dh4t1!'; htpasswd -nb user 'r3dh4t1!') | base64 -b 0 )"
kind: Secret
metadata:
  name: htpasswd
  namespace: openshift-config
type: Opaque
EOF
```

### Change OAuth config

{% hint style="warning" %}
It overwrites the OAuth config
{% endhint %}

```text
oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
    - htpasswd:
        fileData:
          name: htpasswd
      mappingMethod: claim
      name: Local
      type: HTPasswd
EOF
```

## Add your private marketplace

{% embed url="https://github.com/rbo/openshift-examples/tree/master/operator/simple-application-operator" %}

## Add application operator to your namespace

Create OLM Service Account

```text
oc create -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: olm
  namespace: simple-application-operator
EOF
```

Setup roles and role bindings for OLM Service Account

```text
oc apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: olm
  namespace: simple-application-operator
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: olm-bindings
  namespace: simple-application-operator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: scoped
subjects:
- kind: ServiceAccount
  name: olm
  namespace: simple-application-operator
EOF
```

> Create OperatorGroup **as clusteradmin**

```yaml
oc create --as=system:admin -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: simple-application-operator
  namespace: simple-application-operator
spec:
  serviceAccountName: olm
  targetNamespaces:
  - simple-application-operator
EOF
```

Install the operator

```bash
# Get all need informations
$ oc get catalogsources.operators.coreos.com
NAME                  DISPLAY               TYPE   PUBLISHER      AGE
application-catalog   Application catalog   grpc   Robert Bohne   85m

$ oc get svc
NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
application-catalog   ClusterIP   172.30.96.52   <none>        50051/TCP   87m

$ oc port-forward service/application-catalog 50051 50051

# https://github.com/operator-framework/operator-registry#using-the-catalog-locally
$ grpcurl -plaintext  localhost:50051 api.Registry/ListPackages
{
  "name": "simple-application-operator"
}

$ grpcurl -plaintext -d '{"name":"simple-application-operator"}' localhost:50051 api.Registry/GetPackage
{
  "name": "simple-application-operator",
  "channels": [
    {
      "name": "beta",
      "csvName": "simple-application-operator.v0.1.0"
    },
    {
      "name": "stable",
      "csvName": "simple-application-operator.v0.1.0"
    }
  ],
  "defaultChannelName": "stable"
}
```

```yaml
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: simple-application-operator
  namespace: simple-application-operator
spec:
  channel: stable
  name: simple-application-operator
  source: application-catalog
  sourceNamespace: simple-application-operator
EOF
```

## ToDo

* [ ] Create doc bug: `The Subscription "etcd" is invalid: spec.sourceNamespace: Required value`
