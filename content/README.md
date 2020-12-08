---
title: OpenShift Examples
hero: "This is my (Robert Bohne) personal OpenShift Examples and Notice collection. ( Including a lot of typos \U0001F609)"
description: "..."
---

# OpenShift Examples

![](openshift-examples.png)

## Run OpenShift on your Hetzner Server

[https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4)

## Run OCP on your laptop

### OpenShift 4

[Code Ready Containers](https://github.com/code-ready/crc)

### OpenShift 3

- [Container Development Kit](https://developers.redhat.com/products/cdk/overview)
- Or simple `oc cluster up`
```text
oc cluster up --image=registry.access.redhat.com/openshift3/ose \
  --public-hostname=localhost
```

## Usefull Red Hat Solutions article

|Article|Note|
|---|---|
|[How can a user update OpenShift 4 console route](https://access.redhat.com/solutions/4539491)||
|[Red Hat Operators Supported in Disconnected Mode](https://access.redhat.com/articles/4740011)||
|[Support Policies for Red Hat OpenShift Container Platform Clusters - Deployments Spanning Multiple Sites(Data Centers/Regions)](https://access.redhat.com/articles/3220991)||

## Usefull commands

### Easy install jq on RHEL

```text
curl -O -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq
```

#### jq examples

**PVC CSV**

```text
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

### OpenShift certificate overview:

```text
find /etc/origin/master/ /etc/origin/node -name "*.crt" -printf '%p - ' -exec openssl x509 -noout -subject -in {} \;
```

### kubectl/oc patch

For example:
```
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

#### Get IP Addresses without ip or ifconfig?

##### Command
```bash
cat /proc/net/fib_trie
```

##### Sample outpout
```
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

##### Command

```text
cat /proc/net/fib_trie | grep "|--"   | egrep -v "0.0.0.0| 127."
```

##### Sample output

```
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


### List all Services from ansible-service-broker

```text
 curl -k -s $(oc get broker ansible-service-broker -o go-template='{{.spec.url}}v2/catalog') | jq ' .services[] | {Name: .name, displayName: .metadata.displayName}'
{
  "Name": "dh--latest",
  "displayName": "Hello World (APB)"
}
```

### List all services from template broker:

```text
curl -s -k -X GET -H "Authorization: Bearer $(oc whoami -t)" -H "X-Broker-Api-Version: 2.7"  https://192.168.37.1:8443/brokers/template.openshift.io/v2/catalog | jq ' .services[] | {Name: .name, displayName: .metadata.displayName}'
```

### List all services from service catalog

```text
curl -s -k -X GET -H "Authorization: Bearer $(oc whoami -t)" https://192.168.37.1:8443/apis/servicecatalog.k8s.io/v1alpha1/serviceclasses | jq ' .items[] | { brokerName: .brokerName, name: .metadata.name, displayName: .externalMetadata.displayName } '
```
## Stargazers over time

![Stargazers over time](https://starcharts.herokuapp.com/rbo/openshift-examples.svg)

