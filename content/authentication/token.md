# Service Account authentication via Token

Official solution: [How to get the authentication token for an OpenShift Service account](https://access.redhat.com/solutions/2972601)

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
token:           eyJhbGciOiJSUzI1NiIsImtpZCI6Iml0REV6eVlwcWlFRTVYVlVGZDh1SUtQdFBzWmNGUFUyUU9oeFJod1FxTE0ifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJzYS10ZXN0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImV4dGVybmFsLXBpcGVsaW5lLXVzZXItdG9rZW4tc2R4Y2siLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZXh0ZXJuYWwtcGlwZWxpbmUtdXNlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjkwZjczYWE0LWY3YzAtNDVlZC1iOTljLWRlYzE3ZDNmZDg2NCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpzYS10ZXN0OmV4dGVybmFsLXBpcGVsaW5lLXVzZXIifQ.UqSbr1W2T4NGo9KDE1OZrGLqc-0Va5T-5illyxYegLxnTxhh-Keu6nc2-Cx21leV1vWcVt9p34VJCL5cUA9jKgkb7TNGnM8CW9BRn3bidbX5uaWzPflYGYzxok6QESA0eTMDtGecCDH1ixVPvJxws0Ipsdon5PpkmXbibR3YHjBEAsGFaiWK0oRZv8AE5uRUGOUAbw9kI0WZLoOOGtDdAfAHAtBACIkL4I4ZsqvFrUo8-bnWv9-OpsmvaOY4z0Uzc4tvIDtjWOG1IBwcDFpPUKJ68EqBOVdNxIkArdWej88wZ1PSRxSewm-sOYms2tH1Vs10RNpnY6TZqrzjAO0egQ
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
token:           eyJhbGciOiJSUzI1NiIsImtpZCI6Iml0REV6eVlwcWlFRTVYVlVGZDh1SUtQdFBzWmNGUFUyUU9oeFJod1FxTE0ifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJzYS10ZXN0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImV4dGVybmFsLXBpcGVsaW5lLXVzZXItdG9rZW4tY3I3bnEiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiZXh0ZXJuYWwtcGlwZWxpbmUtdXNlciIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjkwZjczYWE0LWY3YzAtNDVlZC1iOTljLWRlYzE3ZDNmZDg2NCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpzYS10ZXN0OmV4dGVybmFsLXBpcGVsaW5lLXVzZXIifQ.S0vCY3W73655J1M3xu9ZiRHpl6ypPwCG95YPwIC9iOstL2wlX0AXflyolcofPo6xaklX6euYhWt4-2wnBLvEBiTJL1AtmZXLd9hL3UULxQC8X9j6DNzgqNs8BphTa6tFz1BusJCvUNs0ilgn--aysI0h3HHJDDRJlyp991pNKZ8Vz8uR2YRMHAIXXvOS9hbhcA2P2-QLw8USBfjlNnYm1vhFEqM4YrcbD_vNqlM9kSRYJpmQIw9bSeVUgVrszT_XEgsJaxzU9fRjn6Ip10RfFJ-95j1dR3rxHJ0RS0VrrcVsrk25UeuroMkdxYNQE4RBVAdOwchmOSy11aoJv5EEMQ
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


