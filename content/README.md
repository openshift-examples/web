---
title: OpenShift Examples
hero: "This is my (Robert Bohne) personal OpenShift Examples and Notice collection. ( Including a lot of typos \U0001F609)"
description: "..."
ignore_macros: true
---

# [OpenShift Examples](https://examples.openshift.pub/) gathered by [Robert Bohne](https://github.com/rbo)

![](openshift-examples.png)

The OpenShift Examples is a personal collection of valuable information, code snippets, and practical
demonstrations related to OpenShift and Kubernetes. It serves as a repository of Robert's own experiences
& contributions, solutions, and best practices in managing and deploying applications on OpenShift.

Contributions to this collection are warmly welcomed and highly appreciated!
They foster collaboration and knowledge sharing within the OpenShift community,
making the repository even more valuable as a collective resource.

Feel free to explore the examples, contribute your own insights,
and benefit from the expertise shared in this repository.

Please visit <https://examples.openshift.pub/>

## Usefull Red Hat Solutions article

|Article|Note|
|---|---|
|[How can a user update OpenShift 4 console route](https://access.redhat.com/solutions/4539491)||
|[Red Hat Operators Supported in Disconnected Mode](https://access.redhat.com/articles/4740011)||
|[Support Policies for Red Hat OpenShift Container Platform Clusters - Deployments Spanning Multiple Sites(Data Centers/Regions)](https://access.redhat.com/articles/3220991)||
|[Red Hat OpenShift Container Platform Update Graph](https://access.redhat.com/labs/ocpupgradegraph/update_channel)||
|[Consolidated Troubleshooting Article OpenShift Container Platform 4.x](https://access.redhat.com/articles/4217411)||
|[Red Hat Container Support Policy](https://access.redhat.com/articles/2726611)||
|[Red Hat Enterprise Linux Container Compatibility Matrix](https://access.redhat.com/support/policy/rhel-container-compatibility)||
|[Consolidated Troubleshooting Article OpenShift Container Platform 4.x](https://access.redhat.com/articles/4217411)||
|[Red Hat OpenShift Container Platform Life Cycle Policy](https://access.redhat.com/support/policy/updates/openshift)||

## Glossary

|Term|Definition|
|---|---|
|Container runtime|Container runtimes, or specificially OCI Runtimes are things like runc, crun, kata, gvisor.|
|Container engines|Container Engines pull and push container images from container registries, configure OCI Runtime Specifications and launch OCI Runtimes. For example CRI-O, ContainerD|

## Usefull commands

### Easy install jq on RHEL

```text
curl -O -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq
```

#### jq examples

##### PVC CSV

```bash
oc get pvc --all-namespaces -o json | jq -r  ' .items[] |  [.metadata.namespace,.metadata.name,.status.capacity.storage|tostring]|@csv'
```

### Print certificate from secret

```text
oc get secret -n openshift-web-console webconsole-serving-cert -o json | jq -r '.data."tls.crt"' | base64 -d > foo.pem
# Can't use openssl x509, x509 do not support bundles
openssl crl2pkcs7 -nocrl -certfile foo.pem | openssl pkcs7 -print_certs  -noout
```

### Check certificate from master-api

```text
echo -n | openssl s_client -connect q.bohne.io:8443 -servername q.bohne.io 2>/dev/null | openssl x509 -noout -subject -issuer
```

### OpenShift certificate overview

```text
find /etc/origin/master/ /etc/origin/node -name "*.crt" -printf '%p - ' -exec openssl x509 -noout -subject -in {} \;
```

### kubectl/oc patch

For example:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster \
    --type='json' \
    --patch='[
        {"op": "replace", "path": "/spec/managementState", "value": "Managed"},
        {"op": "replace", "path": "/spec/rolloutStrategy", "value": "Recreate"},
        {"op": "replace", "path": "/spec/storage", "value": {"pvc":{"claim": "image-registry-pvc" }}}
    ]'
```

**patch definition:**

* JSON Merge Patch RFC 7386: [https://tools.ietf.org/html/rfc7386](https://tools.ietf.org/html/rfc7386)
* JSON Patch RFC 6902: [https://tools.ietf.org/html/rfc6902](https://tools.ietf.org/html/rfc6902)
* The JSONPath websites offers a good description which operation can be used an how: [http://jsonpatch.com/](http://jsonpatch.com/)

Blog post: [https://labs.consol.de/development/2019/04/08/oc-patch-unleashed.html](https://labs.consol.de/development/2019/04/08/oc-patch-unleashed.html)

### Commands inside a POD

#### Get IP Addresses without ip or ifconfig

```bash
$ cat /proc/net/fib_trie
Main:
  +-- 0.0.0.0/0 3 0 4
     +-- 0.0.0.0/4 2 0 2
        |-- 0.0.0.0
           /0 universe UNICAST
        +-- 10.128.0.0/14 2 0 2
           |-- 10.128.0.0
              /14 universe UNICAST
           +-- 10.131.0.0/23 2 0 2
              +-- 10.131.0.0/28 2 0 2
                 |-- 10.131.0.0
                    /32 link BROADCAST
                    /23 link UNICAST
                 |-- 10.131.0.14
                    /32 host LOCAL
              |-- 10.131.1.255
                 /32 link BROADCAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /32 link BROADCAST
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     |-- 172.30.0.0
        /16 universe UNICAST
     |-- 224.0.0.0
        /4 universe UNICAST
Local:
  +-- 0.0.0.0/0 3 0 4
     +-- 0.0.0.0/4 2 0 2
        |-- 0.0.0.0
           /0 universe UNICAST
        +-- 10.128.0.0/14 2 0 2
           |-- 10.128.0.0
              /14 universe UNICAST
           +-- 10.131.0.0/23 2 0 2
              +-- 10.131.0.0/28 2 0 2
                 |-- 10.131.0.0
                    /32 link BROADCAST
                    /23 link UNICAST
                 |-- 10.131.0.14
                    /32 host LOCAL
              |-- 10.131.1.255
                 /32 link BROADCAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /32 link BROADCAST
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     |-- 172.30.0.0
        /16 universe UNICAST
     |-- 224.0.0.0
        /4 universe UNICAST
```

```bash
$ cat /proc/net/fib_trie | grep "|--"   | egrep -v "0.0.0.0| 127."
           |-- 10.128.0.0
                 |-- 10.131.0.0
                 |-- 10.131.0.14
              |-- 10.131.1.255
     |-- 172.30.0.0
     |-- 224.0.0.0
           |-- 10.128.0.0
                 |-- 10.131.0.0
                 |-- 10.131.0.14
              |-- 10.131.1.255
     |-- 172.30.0.0
     |-- 224.0.0.0
```

#### cURL & Kubernetes/OpenShift API examples

```text
$ curl --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
  --header "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc.cluster.local/version

{
  "major": "1",
  "minor": "16+",
  "gitVersion": "v1.16.2",
  "gitCommit": "4320e48",
  "gitTreeState": "clean",
  "buildDate": "2020-01-21T19:50:59Z",
  "goVersion": "go1.12.12",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

## Stargazers over time

[![Stargazers over time](https://starchart.cc/openshift-examples/web.svg)](https://starchart.cc/openshift-examples/web)
