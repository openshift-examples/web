---
title: Token
linktitle: Token
weight: 21100
description: TBD
---
# Service Account authentication via Token

Official solutions (KCS):
 * [How to get the authentication token for an OpenShift Service account](https://access.redhat.com/solutions/2972601)
 * [What are the automatically generated secrets for every service account?](https://access.redhat.com/solutions/4995781)

## Create service account (sa)
```bash
oc create sa external-pipeline-user
```

## Get service account details

```bash
$ oc get serviceaccount/external-pipeline-user -o yaml

apiVersion: v1
imagePullSecrets:
- name: external-pipeline-user-dockercfg-2kjrl
kind: ServiceAccount
metadata:
  creationTimestamp: "2020-10-12T13:56:11Z"
  name: external-pipeline-user
  namespace: sa-test
  resourceVersion: "19995538"
  selfLink: /api/v1/namespaces/sa-test/serviceaccounts/external-pipeline-user
  uid: 90f73aa4-f7c0-45ed-b99c-dec17d3fd864
secrets:
- name: external-pipeline-user-token-cr7nq
- name: external-pipeline-user-dockercfg-2kjrl

$ oc describe serviceaccount/external-pipeline-user
Name:                external-pipeline-user
Namespace:           sa-test
Labels:              <none>
Annotations:         <none>
Image pull secrets:  external-pipeline-user-dockercfg-2kjrl
Mountable secrets:   external-pipeline-user-token-cr7nq
                     external-pipeline-user-dockercfg-2kjrl
Tokens:              external-pipeline-user-token-cr7nq
                     external-pipeline-user-token-sdxck
Events:              <none>

```

## Get Token

```bash

TOKEN=$(oc serviceaccounts get-token external-pipeline-user)

$ oc login --token=$TOKEN
Logged into "https://api.demo.openshift.pub:6443" as "system:serviceaccount:sa-test:external-pipeline-user" using the token provided.

You don't have any projects. Contact your system administrator to request a project.
$ oc whoami
system:serviceaccount:sa-test:external-pipeline-user

```

### List of secrets
```bash
$ oc get secrets | grep external-pipeline-user
external-pipeline-user-dockercfg-2kjrl   kubernetes.io/dockercfg               1      25m
external-pipeline-user-token-cr7nq       kubernetes.io/service-account-token   4      25m
external-pipeline-user-token-sdxck       kubernetes.io/service-account-token   4      25m
```

Both secrets

 * `external-pipeline-user-token-cr7nq`
 * `external-pipeline-user-token-sdxck`

contains a valid token.

The only differents is an annotation `kubernetes.io/created-by: openshift.io/create-dockercfg-secrets`.

Token with the annotation is made for container image registry during the dockercfg secret creation. For details please check the [source code of create_dockercfg_secrets.go](https://github.com/openshift/openshift-controller-manager/blob/master/pkg/serviceaccounts/controllers/create_dockercfg_secrets.go).



```bash
$ oc describe secrets/external-pipeline-user-token-sdxck
Name:         external-pipeline-user-token-sdxck
Namespace:    sa-test
Labels:       <none>
Annotations:  kubernetes.io/created-by: openshift.io/create-dockercfg-secrets
              kubernetes.io/service-account.name: external-pipeline-user
              kubernetes.io/service-account.uid: 90f73aa4-f7c0-45ed-b99c-dec17d3fd864

Type:  kubernetes.io/service-account-token

Data
====
token:           eyJhbxxxxxxxxxxx
ca.crt:          8826 bytes
namespace:       7 bytes
service-ca.crt:  10039 bytes

$ oc describe secrets/external-pipeline-user-token-cr7nq
Name:         external-pipeline-user-token-cr7nq
Namespace:    sa-test
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: external-pipeline-user
              kubernetes.io/service-account.uid: 90f73aa4-f7c0-45ed-b99c-dec17d3fd864

Type:  kubernetes.io/service-account-token

Data
====
service-ca.crt:  10039 bytes
token:           eyJhbxxxxxxxxxx
ca.crt:          8826 bytes
namespace:       7 bytes


```




#### Both tokens works very well

```bash
$ TOKEN_cr7nq=$(oc get secret/external-pipeline-user-token-cr7nq -o jsonpath={.data.token} | base64 -d)
$ TOKEN_sdxck=$(oc get secret/external-pipeline-user-token-sdxck -o jsonpath={.data.token} | base64 -d)

$ oc login --token=$TOKEN_cr7nq
Logged into "https://api.demo.openshift.pub:6443" as "system:serviceaccount:sa-test:external-pipeline-user" using the token provided.

$ oc login --token=$TOKEN_sdxck
Logged into "https://api.demo.openshift.pub:6443" as "system:serviceaccount:sa-test:external-pipeline-user" using the token provided.
```

#### Inspect tokens

 * [Download jwt command line tool](https://github.com/mike-engel/jwt-cli/releases)

```bash
$ oc get secrets | grep external-pipeline-user
external-pipeline-user-dockercfg-2kjrl   kubernetes.io/dockercfg               1      25m
external-pipeline-user-token-cr7nq       kubernetes.io/service-account-token   4      25m
external-pipeline-user-token-sdxck       kubernetes.io/service-account-token   4      25m



$ oc get secrets external-pipeline-user-token-cr7nq -o jsonpath='{.data.token}' | base64 --decode | jwt decode -

Token header
------------
{
  "alg": "RS256",
  "kid": "itDEzyYpqiEE5XVUFd8uIKPtPsZcFPU2QOhxRhwQqLM"
}

Token claims
------------
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "sa-test",
  "kubernetes.io/serviceaccount/secret.name": "external-pipeline-user-token-cr7nq",
  "kubernetes.io/serviceaccount/service-account.name": "external-pipeline-user",
  "kubernetes.io/serviceaccount/service-account.uid": "90f73aa4-f7c0-45ed-b99c-dec17d3fd864",
  "sub": "system:serviceaccount:sa-test:external-pipeline-user"
}

$ oc get secrets external-pipeline-user-token-sdxck    -o jsonpath='{.data.token}' | base64 --decode | jwt decode -

Token header
------------
{
  "alg": "RS256",
  "kid": "itDEzyYpqiEE5XVUFd8uIKPtPsZcFPU2QOhxRhwQqLM"
}

Token claims
------------
{
  "iss": "kubernetes/serviceaccount",
  "kubernetes.io/serviceaccount/namespace": "sa-test",
  "kubernetes.io/serviceaccount/secret.name": "external-pipeline-user-token-sdxck",
  "kubernetes.io/serviceaccount/service-account.name": "external-pipeline-user",
  "kubernetes.io/serviceaccount/service-account.uid": "90f73aa4-f7c0-45ed-b99c-dec17d3fd864",
  "sub": "system:serviceaccount:sa-test:external-pipeline-user"
}

```


