# Certificates & OpenShift
## General: Create a self signed certificate 

1) Adjust `openssl.self-signed-certificate.conf`
2) Create self signed certificate

      openssl.self-signed-certificate.conf:
      ```ini
      [req]
      distinguished_name = req_distinguished_name
      x509_extensions = v3_req
      prompt = no

      [req_distinguished_name]
      C = US
      ST = VA
      L = SomeCity
      O = MyCompany
      OU = MyDivision
      CN = nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com

      [v3_req]
      keyUsage = nonRepudiation, digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth
      subjectAltName = @alt_names

      [alt_names]
      DNS.1 = nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com
      DNS.2 = company.com
      DNS.3 = company.net
      ```

      Command:
      ```
      openssl req -x509 -nodes -days 730 \
        -newkey rsa:2048 -keyout cert.pem \
        -out cert.pem \
        -config openssl.self-signed-certificate.conf \
        -extensions 'v3_req'
      ```

3) Print self signed certificate
    ``` 
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

1) Adjust openssl configurations:
    1) Root CA informations at file `openssl.root-ca.conf`
        ```ini
        # OpenSSL root CA configuration file.

        [ req ]
        # Options for the `req` tool (`man req`).
        default_bits        = 2048
        distinguished_name  = req_distinguished_name
        string_mask         = utf8only

        # SHA-1 is deprecated, so use SHA-2 instead.
        default_md          = sha256

        # Extension to add when the -x509 option is used.
        x509_extensions     = v3_ca
        req_extensions      = v3_req

        [ v3_req ]
        # Extensions to add to a certificate request
        basicConstraints = CA:FALSE
        keyUsage = nonRepudiation, digitalSignature, keyEncipherment
        subjectAltName = @alt_names

        [alt_names]
        DNS.1 = rootca.example.com
        # DNS.2 = *.pass.example.com
        # DNS.3 = ...
        # DNS.4 = ...


        [ req_distinguished_name ]
        # See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
        countryName                     = Country Name (2 letter code)
        stateOrProvinceName             = State or Province Name
        localityName                    = Locality Name
        0.organizationName              = Organization Name
        organizationalUnitName          = Organizational Unit Name
        commonName                      = Common Name
        emailAddress                    = Email Address

        # Optionally, specify some defaults.
        countryName_default             = DE
        stateOrProvinceName_default     = Bavaria
        localityName_default            = Munich
        0.organizationName_default      = My Private Root CA
        organizationalUnitName_default  = My Private Root CA
        emailAddress_default            = email@domain.tld
        commonName_default              = rootca.example.com

        [ v3_ca ]
        # Extensions for a typical CA (`man x509v3_config`).
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer
        basicConstraints = critical, CA:true
        keyUsage = critical, digitalSignature, cRLSign, keyCertSign

        [ v3_intermediate_ca ]
        # Extensions for a typical intermediate CA (`man x509v3_config`).
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer
        basicConstraints = critical, CA:true, pathlen:0
        keyUsage = critical, digitalSignature, cRLSign, keyCertSign

        [ server_cert ]
        # Extensions for server certificates (`man x509v3_config`).
        basicConstraints = CA:FALSE
        nsCertType = server
        nsComment = "OpenSSL Generated Server Certificate"
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer:always
        keyUsage = critical, digitalSignature, keyEncipherment
        extendedKeyUsage = serverAuth

        [ crl_ext ]
        # Extension for CRLs (`man x509v3_config`).
        authorityKeyIdentifier=keyid:always

        ```
    2) Certificate informations at file `openssl.certificate.conf`
        ```ini
        # OpenSSL root CA configuration file.

        [ req ]
        # Options for the `req` tool (`man req`).
        default_bits        = 2048
        distinguished_name  = req_distinguished_name
        string_mask         = utf8only

        # SHA-1 is deprecated, so use SHA-2 instead.
        default_md          = sha256

        # Extension to add when the -x509 option is used.
        x509_extensions     = v3_ca
        req_extensions      = v3_req

        [ v3_req ]
        # Extensions to add to a certificate request
        basicConstraints = CA:FALSE
        keyUsage = nonRepudiation, digitalSignature, keyEncipherment
        subjectAltName = @alt_names

        [alt_names]
        DNS.1 = api.example.com
        DNS.2 = *.pass.example.com
        DNS.3 = nginx-ex-ssl-stc-pipeline.6923.rh-us-east-1.openshiftapps.com
        # DNS.4 = ...


        [ req_distinguished_name ]
        # See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
        countryName                     = Country Name (2 letter code)
        stateOrProvinceName             = State or Province Name
        localityName                    = Locality Name
        0.organizationName              = Organization Name
        organizationalUnitName          = Organizational Unit Name
        commonName                      = Common Name
        emailAddress                    = Email Address

        # Optionally, specify some defaults.
        countryName_default             = DE
        stateOrProvinceName_default     = Bavaria
        localityName_default            = Munich
        0.organizationName_default      = Private
        organizationalUnitName_default  = Private
        emailAddress_default            = email@domain.tld
        commonName_default              = api.example.com

        [ v3_ca ]
        # Extensions for a typical CA (`man x509v3_config`).
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer
        basicConstraints = critical, CA:true
        keyUsage = critical, digitalSignature, cRLSign, keyCertSign

        [ v3_intermediate_ca ]
        # Extensions for a typical intermediate CA (`man x509v3_config`).
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always,issuer
        basicConstraints = critical, CA:true, pathlen:0
        keyUsage = critical, digitalSignature, cRLSign, keyCertSign

        [ server_cert ]
        # Extensions for server certificates (`man x509v3_config`).
        basicConstraints = CA:FALSE
        nsCertType = server
        nsComment = "OpenSSL Generated Server Certificate"
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer:always
        keyUsage = critical, digitalSignature, keyEncipherment
        extendedKeyUsage = serverAuth

        [ crl_ext ]
        # Extension for CRLs (`man x509v3_config`).
        authorityKeyIdentifier=keyid:always
        ```

2) Generate the root (GIVE IT A PASSWORD IF YOU'RE NOT AUTOMATING SIGNING!):
    ```
    openssl genrsa -aes256 -out ca.key 2048

    openssl req -config openssl.root-ca.conf \
      -new -x509 -days 7300 -key ca.key -sha256 \
      -extensions v3_ca -out ca.crt
    ```
3) Generate the domain key:
    ```
    openssl genrsa -out yoursite.org.key 2048
    ```
4) Generate the certificate signing request
    ```
    openssl req -config openssl.certificate.conf \
      -sha256 -new -key yoursite.org.key -out yoursite.org.csr
    ```
5) Sign the request with your root key
    ```
    openssl x509 -sha256 -req -in yoursite.org.csr \
      -CA ca.crt -CAkey ca.key -CAcreateserial \
      -out yoursite.org.crt -days 7300 \
      -extfile openssl.certificate.conf \
      -extensions v3_req 
    ```
6) Checking certificate
    ```
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

7) Rollout own root ca
    
    https://access.redhat.com/solutions/1519813
    ```
    update-ca-trust enable
    cp ca.crt /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract
    ```



## OpenShift 4 setup own router/ingress certifcate

Official docs:
  * [Replacing the default ingress certificate
](https://docs.openshift.com/container-platform/4.2/authentication/certificates/replacing-default-ingress-certificate.html#replacing-default-ingress_replacing-default-ingress)
  * [Setting a custom default certificate
](https://docs.openshift.com/container-platform/4.2/networking/ingress-operator.html#nw-ingress-setting-a-custom-default-certificate_configuring-ingress)

**WARNING:** If the default certificate is replaced, it **must** be signed by a public certificate authority already included in the CA bundle as provided by the container userspace.

1) Create secret with certificates
    ```
    oc create secret tls router-certs \
      --cert=letsencrypt/fullchain.crt \
      --key=letsencrypt/cert.key \
      -n openshift-ingress
    ```
2) Add secret to ingresscontroller
    ```
    oc patch ingresscontroller default \
      -n openshift-ingress-operator \
      --type=merge \
      --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'
    ```

## OpenShift 4 - Inject own CA to trusted CA bundle

Quick notes not tested yet:

```

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

    openssl crl2pkcs7 -nocrl -certfile <(oc get secret/router-certs -o yaml --export | grep tls.crt | cut -f2 -d ':' | tr -d ' ' |base64 -D ) | openssl pkcs7 -print_certs  -noout

    openssl crl2pkcs7 -nocrl -certfile <(oc get secret/grafana-tls -o json --export | jq -r '.data."tls.crt"'  | base64 -D ) | openssl pkcs7 -print_certs  -noout

    oc get svc --all-namespaces  -o=custom-columns="tls:.metadata.annotations.service\.alpha\.openshift\.io/serving-cert-secret-name,namespace:.metadata.namespace"  | grep -v '^<none>' | awk '{ print "oc delete secret/" $1 " -n " $2}'

## OpenShift 3 rollout named certificate and new root-ca *NOT RECOMMEND*!

1) Adjust inventory file, details above
    ```
    openshift_master_overwrite_named_certificates=true
    # cat isrgrootx1.pem intermediate.crt >> ca-bundle.pem"
    openshift_master_named_certificates=[{"certfile": "/root/certificates/cert.crt", "keyfile": "/root/certificates/cert.key", "cafile": "/root/certificates/ca-bundle.pem"}]
    openshift_hosted_router_certificate={"certfile": "/root/certificates/cert.crt", "keyfile": "/root/certificates/cert.key", "cafile": "/root/certificates/ca-bundle.pem
    ```

2) The chaos begins: 

    [Redeploying Master Certificates Only](https://docs.openshift.com/container-platform/3.11/install_config/redeploying_certificates.html#redeploying-master-certificates)

    1) Adjust master-config.yml on any master
        ```
        namedCertificates:
        - certFile:  /etc/origin/master/named_certificates/stormshift.crt
        keyFile:  /etc/origin/master/named_certificates/stormshift.key
        names:
            - "master.ocp1..."
        ```
        Restart master api and controllers
        ```
        master-restart api
        master-restart controllers
        ```

    2) Rollout new kubeconfig to all nodes, because of [Issuer 1635251](https://bugzilla.redhat.com/show_bug.cgi?id=1635251):

        [Manually recreate OpenShift Node TLS bootstrapped certificates and kubeconfig files.](https://access.redhat.com/solutions/3782361)

        Some usefull ansible commands:
        ```
        ansible -i /root/stc/inventory -m copy \
          -a 'src=/root/bootstrap.kubeconfig dest=/etc/origin/node/bootstrap.kubeconfig' \
          nodes
        ansible -i /root/stc/inventory -m shell \
          -a 'cp /etc/origin/master/admin.kubeconfig /etc/origin/node/bootstrap.kubeconfig' \
          masters
        ```
    3) Regenerate any service signing certificate

        Create a list oc delete commands to delete all secrets with tls certificates create via an service:
        ```
        oc get svc --all-namespaces \ 
          -o=custom-columns="tls:.metadata.annotations.service\.alpha\.openshift\.io/serving-cert-secret-name,namespace:.metadata.namespace" \
          | grep -v '^<none>' \
          | awk '{ print "oc delete secret/" $1 " -n " $2}'
        ```
        Don't forget to restart all pods!

    4) CA Bunle update ansible-service-broker

        Check CSB: `oc get ClusterServiceBroker`

        [Update caBundle](https://github.com/openshift/ansible-service-broker/blob/master/docs/troubleshooting.md#resolution-provide-cabundle-to-service-catalog)

    5 In case you still have problems with the OpenShift Web Console: Redeploy OpenShift Web ConSole
    ```
      oc delete secret webconsole-serving-cert
      oc delete svc/webconsole
      and finally running the ansible playbook for the webconsole
      ansible-playbook -i inventory/hosts.localhost playbooks/openshift-web-console/config.yml
    ```
    Source: https://github.com/openshift/origin/issues/20005