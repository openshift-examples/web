---
hero: "This is my (Robert Bohne) personal OpenShift Examples and Notice collection. ( Including a lot of typos \U0001F609)"
---

# OpenShift Examples

![](openshift-examples.png)

## Run OpenShift on your Hetzner Server

[https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4](https://github.com/RedHat-EMEA-SSA-Team/hetzner-ocp4)

## Run OCP on your laptop

### OpenShift 3

```text
oc cluster up --image=registry.access.redhat.com/openshift3/ose \
  --public-hostname=localhost
```
### OpenShift 4

[https://github.com/code-ready/crc](https://github.com/code-ready/crc)

{% embed url="https://developers.redhat.com/products/cdk/overview" %}

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

## Stargazers over time

![Stargazers over time](https://starcharts.herokuapp.com/rbo/openshift-examples.svg)

