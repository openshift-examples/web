---
title: Certificates
linktitle: Certificates
weight: 26000
description: TBD
---

# Certificates

## Usefull OpenSSL Comments

### Get the list of certificates from a secrets

{% raw %}
```bash

SECRET=letsencrypt-router-certs

openssl crl2pkcs7 -nocrl -certfile \
  <(oc get secrets $SECRET -o go-template='{{ index .data "tls.crt" | base64decode }}' ) \
  | openssl pkcs7 -print_certs  -noout

```
{% endraw %}

## General: Create a self signed certificate

### 1) Create [openssl.self-signed-certificate.conf](certificate/openssl.self-signed-certificate.conf)


=== "Download"

    ```
    curl -L -O {{ page.canonical_url }}openssl.self-signed-certificate.conf
    ```

=== "openssl.self-signed-certificate.conf"

    {% raw %}
    ```ini
    --8<-- "content/certificate/openssl.self-signed-certificate.conf"
    ```
    {% endraw %}


### 2) Create self signed certificate

```bash

openssl req -x509 -nodes -days 730 \
  -newkey rsa:2048 -keyout cert.pem \
  -out cert.pem \
  -config openssl.self-signed-certificate.conf \
  -extensions 'v3_req'

```

### 3) Print self signed certificate

```bash
$ openssl x509 -in cert.pem -noout -text
    Certificate:
        Data:
            Version: 3 (0x2)
            Serial Number: 15062780286100647982 (0xd109bedd3ac9302e)
        Signature Algorithm: sha256WithRSAEncryption
            Issuer: C=US, ST=VA, L=SomeCity, O=MyCompany, OU=MyDivision, CN=nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com
            Validity
                Not Before: Apr  7 13:26:38 2019 GMT
                Not After : Apr  6 13:26:38 2021 GMT
            Subject: C=US, ST=VA, L=SomeCity, O=MyCompany, OU=MyDivision, CN=nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com
    [...snipped...]
            X509v3 extensions:
                X509v3 Key Usage:
                    Digital Signature, Non Repudiation, Key Encipherment
                X509v3 Extended Key Usage:
                    TLS Web Server Authentication
                X509v3 Subject Alternative Name:
                    DNS:nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com, DNS:company.com, DNS:company.net
    [...snipped...]
```

## General: Own root ca and certificate

### Create OpenSSL Configuration

#### Create [openssl.root-ca.conf](certificate/openssl.root-ca.conf)

=== "Download"

    ```
    curl -L -O {{ page.canonical_url }}openssl.root-ca.conf
    ```

=== "openssl.root-ca.conf"

    {% raw %}
    ```ini
    --8<-- "content/certificate/openssl.root-ca.conf"
    ```
    {% endraw %}


#### Create [openssl.certificate.conf](certificate/openssl.certificate.conf)

=== "Download"

    ```
    curl -L -O {{ page.canonical_url }}openssl.certificate.conf
    ```

=== "openssl.certificate.conf"

    {% raw %}
    ```ini
    --8<-- "content/certificate/openssl.certificate.conf"
    ```
    {% endraw %}

### Adjust openssl.certificate.conf

Change commonName, DNS...

### Generate the root

```bash
openssl genrsa -aes256 -out ca.key -passout pass:openshift 2048

openssl req -config openssl.root-ca.conf \
  -new -x509 -days 7300 -key ca.key -sha256 \
  -extensions v3_ca -out ca.crt \
  -passin pass:openshift
```

### Generate the domain key

```bash
openssl genrsa -out ssl.key 2048
```

### Generate the certificate signing request

```bash
openssl req -config openssl.certificate.conf \
  -sha256 -new -key ssl.key -out ssl.csr
```

### Sign the request with your root key

```bash
openssl x509 -sha256 -req -in ssl.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out yoursite.org.crt -days 7300 \
  -extfile openssl.certificate.conf \
  -extensions v3_req \
  -passin pass:openshift
```

### Checking certificate

```bash
# Check your homework:
openssl verify -CAfile ca.crt yoursite.org.crt

# Deployed certificate on openshift online and test it:
$ curl -I --cacert ca.crt  --header 'Host: nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com' https://nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com
HTTP/1.1 200 OK
Server: nginx/1.12.1
Date: Sun, 07 Apr 2019 13:47:08 GMT
Content-Type: text/html
Content-Length: 37451
Last-Modified: Sun, 07 Apr 2019 13:08:57 GMT
ETag: "5ca9f669-924b"
Accept-Ranges: bytes
Set-Cookie: 301fe4e688e3d65605266d24021c9c12=dba6b61bf38d9d364b636a33c0341f4a; path=/; HttpOnly; Secure
Cache-control: private
```

### Trust own root CA on your Linux box

<https://access.redhat.com/solutions/1519813>

```bash
update-ca-trust enable
cp -v ca.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract
```

## OpenShift 4 setup own router/ingress certifcate

Official docs:

* [Replacing the default ingress certificate](https://docs.openshift.com/container-platform/latest/authentication/certificates/replacing-default-ingress-certificate.html\#replacing-default-ingress\_replacing-default-ingress)
* [Setting a custom default certificate](https://docs.openshift.com/container-platform/4.2/networking/ingress-operator.html\#nw-ingress-setting-a-custom-default-certificate\_configuring-ingress)

**WARNING:** If the default certificate is replaced, it **must** be signed by a public certificate authority already included in the CA bundle as provided by the container userspace.

1) Create secret with certificates

```bash
oc create secret tls router-certs \
  --cert=letsencrypt/fullchain.crt \
  --key=letsencrypt/cert.key \
  -n openshift-ingress
```

2) Add secret to ingresscontroller

```bash
oc patch ingresscontroller default \
  -n openshift-ingress-operator \
  --type=merge \
  --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'
```

## OpenShift 4 - Inject own CA to trusted CA bundle

Quick notes not tested yet:

```bash
$ oc get cm/trusted-ca-bundle -o yaml -n openshift-console  |grep MyP

$ oc apply -f - <<EOF
apiVersion: v1
data:
  ca-bundle.crt: |
    # MyPrivateCA
    -----BEGIN CERTIFICATE-----
   zzzzz
    -----END CERTIFICATE-----
kind: ConfigMap
metadata:
  name: user-ca-bundle
  namespace: openshift-config
EOF

$ oc patch proxy/cluster \
      --type=merge \
      --patch='{"spec": { "trustedCA": { "name": "user-ca-bundle" }}}'

$ oc get cm/trusted-ca-bundle -o yaml -n openshift-console  |grep MyP
# MyPrivateCA
```

[CONFIGURING A CUSTOM PKI](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.2/html/networking/configuring-a-custom-pki)

## Some usefull openssl commands

```bash

oc get svc --all-namespaces  -o=custom-columns="tls:.metadata.annotations.service\.alpha\.openshift\.io/serving-cert-secret-name,namespace:.metadata.namespace"  | grep -v '^<none>' | awk '{ print "oc delete secret/" $1 " -n " $2}'

```
