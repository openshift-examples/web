# Service Serving Certificate Secrets Example

[Documentation](https://docs.openshift.com/container-platform/3.11/dev_guide/secrets.html#service-serving-certificate-secrets)

## Example Service

```text
apiVersion: v1
kind: Service
metadata:
  name: service-serving-cert
  annotations:
    service.alpha.openshift.io/serving-cert-secret-name: service-serving-cert
spec:
  ports:
  - name: service-serving-cert
    port: 443
    targetPort: 8443
  selector:
    app: service-serving-cert
```

## Check certificate

```text
oc get secret service-serving-cert -o json | jq -r '.data."tls.crt"' | base64 --decode > service-serving-cert.pem

openssl crl2pkcs7 -nocrl -certfile service-serving-cert.pem | openssl pkcs7 -print_certs  -noout
```

## Example commands

```text
$ echo "apiVersion: v1
kind: Service
metadata:
  name: service-serving-cert
  annotations:
    service.alpha.openshift.io/serving-cert-secret-name: service-serving-cert
spec:
  ports:
  - name: service-serving-cert
    port: 443
    targetPort: 8443
  selector:
    app: service-serving-cert" | oc create -f -
service/service-serving-cert created
$ oc get secret service-serving-cert -o json | jq -r '.data."tls.crt"' | base64 --decode > service-serving-cert.pem
$ openssl crl2pkcs7 -nocrl -certfile service-serving-cert.pem | openssl pkcs7 -print_certs  -noout
subject=/CN=service-serving-cert.rbo.svc
issuer=/CN=openshift-service-serving-signer@1545507973

subject=/CN=openshift-service-serving-signer@1545507973
issuer=/CN=openshift-service-serving-signer@1545507973
```

