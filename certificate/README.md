## Create a self signed certificate 


1) Adjust `openssl.self-signed-certificate.conf`

2) Create self signed certificate
   ```
   openssl req -x509 -nodes -days 730 -newkey rsa:2048 -keyout cert.pem -out cert.pem -config openssl.self-signed-certificate.conf -extensions 'v3_req'
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

## Own root ca and certificate

1) Adjust openssl configurations:
   
   Root CA informations at file `openssl.root-ca.conf`
   
   Certificate informations at file `openssl.certificate.conf`

2) Generate the root (GIVE IT A PASSWORD IF YOU'RE NOT AUTOMATING SIGNING!):
    ```
    openssl genrsa -aes256 -out ca.key 2048
    openssl req -config openssl.root-ca.conf -new -x509 -days 7300 -key ca.key -sha256 -extensions v3_ca -out ca.crt
    ```

3) Generate the domain key:
    ```
    openssl genrsa -out yoursite.org.key 2048
    ```

4) Generate the certificate signing request
    ```
    openssl req -config openssl.certificate.conf -sha256 -new -key yoursite.org.key -out yoursite.org.csr
    ```

5) Sign the request with your root key
    ```
    openssl x509 -sha256 -req -in yoursite.org.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out yoursite.org.crt -days 7300 -extfile openssl.certificate.conf -extensions v3_req 
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