---
title: New Page
linktitle: New Page
description: Some information
tags:
  - tagA
  - tagB
---

# Some information


https://keycloakthemes.com/blog/how-to-setup-sign-in-with-google-using-keycloak
https://medium.com/keycloak/using-keycloak-identity-provider-to-secure-openshift-f929a7a0f7f1

apiVersion: v1
data:
  ca.crt: |-
    -----BEGIN CERTIFICATE-----
    MIIDlTCCAn2gAwIBAgIUWMhTpeR0h6PkJETCi71TbayM+4wwDQYJKoZIhvcNAQEL
    BQAwWjEyMDAGA1UEAwwpa2V5Y2xvYWsuYXBwcy5zZW5kbGluZy5jb2UubXVjLnJl
    ZGhhdC5jb20xFzAVBgNVBAoMDlRlc3QgS2V5Y2xvYWsuMQswCQYDVQQGEwJVUzAe
    Fw0yNDAyMDkxNDExMThaFw0yNTAyMDgxNDExMThaMFoxMjAwBgNVBAMMKWtleWNs
    b2FrLmFwcHMuc2VuZGxpbmcuY29lLm11Yy5yZWRoYXQuY29tMRcwFQYDVQQKDA5U
    ZXN0IEtleWNsb2FrLjELMAkGA1UEBhMCVVMwggEiMA0GCSqGSIb3DQEBAQUAA4IB
    DwAwggEKAoIBAQCJrpwksbqZKzReVMjNiDVMwJrrPO51TaQnUgDKJXhAAGBBsCS4
    MchqCBBonn4NOEhOuf555I0ayZexGr7rGtzprkmBmszcGcElm6dqlZitsLKq/lC5
    J8PbJU2vPnNWVu21100ZVSqngFY614IwjHn+nPWbZDuXz7V6eWnGFMqklTYWSjsN
    6c4+/ZiHiG6Tewi5vICnq5i0LbVC5VSPGRCRCJXssfKE2K9/LlF8p4FxmBTvLCEM
    ffZhE4a+7nQpOTypXu8TongiZUg6OAECHtQqXNaU7fdGINx1u/5hYZKSziJ2abGo
    j+thMGU+QvbSbnmHpN0EH3hDwocsn1MLCJ1xAgMBAAGjUzBRMB0GA1UdDgQWBBTD
    Qx8faafJUd+zG3ZdF1ndjjG/eDAfBgNVHSMEGDAWgBTDQx8faafJUd+zG3ZdF1nd
    jjG/eDAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAa30Y+4YOa
    N4KHb0kbcj5cGGwWI+j3xo454dCG39jhMru3eClW8X0n50vHNPB12VpdKdUbJBmC
    u54aqi8Pinf7gFrPfjZAPaLdH4nJBCG02QvbGkl/uMFAcXVWEtAQ7e/329Xn2FiJ
    M7+Npss7zG2Jo/xJReXx23vUHAJYbqpjY3hUPWbbKBT6RbfnqZWqrk2/wGpS29gc
    vjvn2NX2moeUGR4RsQDGecx0do7u0nQYkuuwAiGfOh6czUe5Ii1wnsIELdC+ryrH
    TjnvbqpRaEtGwepmyqN/eANljJnrGBaFxZnrxpeqBCdqgUhvKMnrnEoBzF7OZA3+
    XtZzo9trJzN2
    -----END CERTIFICATE-----
kind: ConfigMap
metadata:
  name: keycloak-coe


spec:
  configuration:
    oauth:
      identityProviders:
        - type: OpenID
          name: keycloak
          openID:
            ca:
              name: keycloak-coe
            clientID: coe-ocp-sendling
            clientSecret:
              name:
            issuer: https://keycloak.apps.sendling.coe.muc.redhat.com/realms/master