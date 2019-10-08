# README

## Content

* [Simple pods](simple-pods.md)
* [EAP / JBoss Clustering / Session replication](eap-cluster.md)
* [Autoscaling & SpringBoot](autoscaling.md)
* [initContainers - DNS & TCP Check](initcontainers.md)  \|
* [Build \(chaining build...\)](build/)  \|
* OpsContainer DaemonSet `oc create -f ops-container-example.yml`
* [Certificates & OpenShift 3/4](https://github.com/rbo/openshift-examples/tree/43511bbb16abaf8280889de74ea12f3649972693/certificate/README.adoc)

## Run OCP on your laptop

### OpenShift 3

```text
oc cluster up --image=registry.access.redhat.com/openshift3/ose \
  --public-hostname=localhost
```

### OpenShift 4

Use [CodeReady Containers](https://github.com/code-ready/crc)

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

