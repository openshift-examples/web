---
title: Basic Authentication (Remote)
linktitle: Basic Authentication (Remote)
description: How to setup remote basic authentication (OpenShift v3)
---
# Basic Authentication \(Remote\)

[https://docs.openshift.com/container-platform/3.3/install\_config/configuring\_authentication.html\#BasicAuthPasswordIdentityProvider](https://docs.openshift.com/container-platform/3.3/install_config/configuring_authentication.html#BasicAuthPasswordIdentityProvider)

```text

oauthConfig:
  ...
  identityProviders:
  - name: my_remote_basic_auth_provider
    challenge: true
    login: true
    mappingMethod: claim
    provider:
      apiVersion: v1
      kind: BasicAuthPasswordIdentityProvider
      url: https://foobar.exmaple.com/basic.php
      ca: /path/to/ca.file
      certFile: /path/to/client.crt
      keyFile: /path/to/client.key
```

basic.php
```php
<?php
    header('Content-Type: application/json');
if (!isset($_SERVER['PHP_AUTH_USER'])) {
    header('WWW-Authenticate: Basic realm="OpenShift Auth Server"');
    header('HTTP/1.0 401 Unauthorized');
    echo '{"error":"Error message"}';
    exit;
} else {
    if ($_SERVER['PHP_AUTH_USER'] == 'rbo' and $_SERVER['PHP_AUTH_PW'] == 'rbo' ){
        echo '{"sub":"rbo", "name": "Robert Bohne", "email":"Robert.Bohne@ConSol.de"}';
    }else{
        header('HTTP/1.0 401 Unauthorized');
        echo '{"error":"Username & passwort falsch.... "}';
    }
}
?>
```
