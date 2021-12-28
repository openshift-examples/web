---
title: Client Certificate
linktitle: Client Certificate
description: Client Certificate
tags:
  - authentication
  - certificate
  - x509
---

# Client Certificate


!!! attention

    Please note before using client certificate authentication:

    * **You can not revoke a client certificate**, ones a client certificate is is compromised you can only restrict access using RBAC. Reistricting access using RBAC might not a solution. For example: you can add `system:cluster-admins` group to your client certificate. I don't know if your cluster survive if you remove all priviliges from this system group.

    * After the certificate signing request is approved and deleted after a while. You don't know what client certificates are signed out there.

    * Signed client certificate is valid for 365 days by default.



#### Create a certificate signing request

=== "Command"


    ```bash
    openssl req -new -newkey rsa:4096 -nodes -keyout rbohne.pem -out rbohne-csr.pem -subj "/CN=rbohne/O=groupA/O=groupB"
    ```

    *Since OpenSSLK 3.0 use `-noenc` instead of `-nodes`*

=== "Example output"

    ```bash
    $ openssl req -new -newkey rsa:4096 -nodes -keyout rbohne.pem -out rbohne-csr.pem -subj "/CN=rbohne/O=groupA/O=groupB"
    Generating a RSA private key
    ...++++
    ...............++++
    writing new private key to 'rbohne.pem'
    -----
    ```

#### Sign request


=== "Command"

    Create CSR object

    ```yaml
    cat <<EOF | oc apply -f -
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
      name: client-cert-rbohne
    spec:
      request: $(cat rbohne-csr.pem | base64 | tr -d '\n')
      signerName: kubernetes.io/kube-apiserver-client
      usages:
      - client auth
    EOF
    ```

    Appropve CSR

    ```bash
    oc adm certificate approve  client-cert-rbohne
    ```

    Export Certificate

    ```bash
    oc get csr/client-cert-rbohne -o jsonpath="{.status.certificate}" | base64 -d > rbohne-crt.pem
    ```

=== "Example Output"

    ```bash
    $ cat <<EOF | oc apply -f -
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
      name: client-cert-rbohne
    spec:
      request: $(cat rbohne-csr.pem | base64 | tr -d '\n')
      signerName: kubernetes.io/kube-apiserver-client
      usages:
      - client auth
    EOF
    certificatesigningrequest.certificates.k8s.io/client-cert-rbohne created

    $ oc get csr
    NAME                 AGE   SIGNERNAME                            REQUESTOR      CONDITION
    client-cert-rbohne   2s    kubernetes.io/kube-apiserver-client   system:admin   Pending

    $ oc adm certificate approve  client-cert-rbohne
    certificatesigningrequest.certificates.k8s.io/client-cert-rbohne approved

    $ oc get csr
    NAME                 AGE   SIGNERNAME                            REQUESTOR      CONDITION
    client-cert-rbohne   14s   kubernetes.io/kube-apiserver-client   system:admin   Approved,Issued

    $ oc get csr/client-cert-rbohne -o jsonpath="{.status.certificate}" | base64 -d > rbohne-crt.pem

    $ openssl x509 -in rbohne-crt.pem -noout -subject -issuer -dates
    subject=O = groupA + O = groupB, CN = rbohne
    issuer=O = https://kubernetes.svc, CN = https://kubernetes.svc
    notBefore=Dec 28 10:16:51 2021 GMT
    notAfter=Dec 22 14:12:27 2022 GMT
    ```

#### Create kubeconfig

=== "Command"

    ```bash
    export KUBECONFIG=$(pwd)/kubeconfig

    kubectl config set-cluster microshift \
      --server=https://192.168.66.4:6443/ \
      --insecure-skip-tls-verify=true

    kubectl config set-credentials rbohne \
      --client-certificate=$( pwd )/rbohne-crt.pem \
      --client-key=$( pwd )/rbohne.pem \
      --embed-certs=true

    kubectl config set-context rbohne-at-microshift \
      --cluster=microshift \
      --user=rbohne \
      --namespace=default

    kubectl config use-context rbohne-at-microshift
    ```

=== "Example output"

    ```bash
    export KUBECONFIG=$(pwd)/kubeconfig

    kubectl config set-cluster microshift \
      --server=https://192.168.66.4:6443/ \
      --insecure-skip-tls-verify=true

    kubectl config set-credentials rbohne \
      --client-certificate=$( pwd )/rbohne-crt.pem \
      --client-key=$( pwd )/rbohne.pem \
      --embed-certs=true


    kubectl config set-context rbohne-at-microshift \
      --cluster=microshift \
      --user=rbohne \
      --namespace=default

    kubectl config use-context rbohne-at-microshift
    W1228 12:29:30.564154 1294981 loader.go:221] Config not found: /tmp/demo/kubeconfig
    W1228 12:29:30.564412 1294981 loader.go:221] Config not found: /tmp/demo/kubeconfig
    Cluster "microshift" set.
    User "rbohne" set.
    Context "rbohne-at-microshift" created.
    Switched to context "rbohne-at-microshift".
    ```