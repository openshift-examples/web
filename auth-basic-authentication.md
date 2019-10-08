# Playing with authentication method "Basic Authentication \(Remote\)"

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

