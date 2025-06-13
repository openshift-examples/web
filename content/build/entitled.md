---
title: Entitled builds on OpenShift 4
linktitle: Entitled
weight: 5200
description: TBD
tags: ['entitlement','build','v4.18']
---
# Entitled builds and OpenShift 4

## What is an entitlement

Technically, the entitlement is a certificate to get access to specific Red Hat Enterprise Linux content and has to be refreshed regularly. Red Hat introduced [Simple Content Access](https://access.redhat.com/documentation/en-us/subscription_central/2021/html/getting_started_with_simple_content_access/index) to simplify the access, for example for container builds.

With `openssl` or `rct` command you can get some information from your entitlement:

```bash
$ rct stat-cert /etc/pki/entitlement/entitlement.pem
Type: Entitlement Certificate
Version: 3.4
DER size: 1610b
Subject Key ID size: 20b
Content sets: 5835
$ openssl x509 -in /etc/pki/entitlement/entitlement.pem -noout -issuer
issuer=C = US, ST = North Carolina, O = "Red Hat, Inc.", OU = Red Hat Network, CN = Red Hat Candlepin Authority, emailAddress = ca-support@redhat.com
$ rct cat-cert  /etc/pki/entitlement/entitlement.pem  | head -n15

+-------------------------------------------+
    Entitlement Certificate
+-------------------------------------------+

Certificate:
    Path: /etc/pki/entitlement/entitlement.pem
    Version: 3.4
    Serial: <Cert Serial>
    Start Date: 2022-07-10 03:19:11+00:00
    End Date: 2023-07-10 03:19:11+00:00
    Pool ID: Not Available

Subject:
    CN: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx
```

How to get the entitlement certificate? If simple content access is enabled at your organisation/redhat account, the insights Operatos automatically provide and refresh and entitlement to your OpenShift 4 Cluster.

You can enable and check the Simple content access at <https://access.redhat.com/management>, it should look like this:

At your OpenShift 4 Cluster you can take a look your entitlement via:

```shell
$ oc get secrets etc-pki-entitlement -n openshift-config-managed  -o jsonpath="{.data.entitlement\.pem}" | base64 -d > entitlement.pem

$ rct cat-cert entitlement.pem | head -n15

+-------------------------------------------+
    Entitlement Certificate
+-------------------------------------------+

Certificate:
    Path: entitlement.pem
    Version: 3.4
    Serial: <Cert Serial>
    Start Date: 2022-07-10 05:06:45+00:00
    End Date: 2023-07-10 05:06:45+00:00
    Pool ID: Not Available

Subject:
    CN: xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx
$
```

Relevant documentation part: [Importing simple content access certificates with Insights Operator](https://docs.openshift.com/container-platform/4.11/support/remote_health_monitoring/insights-operator-simple-access.html)

Another option to get an entitlement from your Red Hat Satellite installation in your environment.
Or copy the entitlement from a subscribed Red Hat Enterprise Linux - this is not recommended, and I assume this is against Red Hat Terms and conditions.

## Prerequisites to run an entitled build

* **Install Builds for Red Hat OpenShift Operator (tested with v1.4.0)**

### Share the entitlement secrets

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}sharedsecret.yaml
    ```

=== "sharedsecret.yaml"

    ```yaml
    --8<-- "content/build/entitled/sharedsecret.yaml"
    ```

#### Add the permissions to share the secret

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}sharedsecret-permissions.yaml
    ```

=== "sharedsecret-permissions.yaml"

    ```yaml
    --8<-- "content/build/entitled/sharedsecret-permissions.yaml"
    ```

## Create a project/namespace

=== "OC"

    ```bash
    oc new-project entitled-build-demo
    ```

### Allow access to shared secrets

In case you want to rollout automaticly for every new project:

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}sharedsecret-allow-namespace.yaml
    ```

=== "sharedsecret-allow-namespace.yaml"

    ```yaml
    --8<-- "content/build/entitled/sharedsecret-allow-namespace.yaml
    ```

## Let's create a build

=== "build.yaml"

    ```yaml
    --8<-- "content/build/entitled/build.yaml
    ```

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}build.yaml
    ```

## Start the build

=== "build.yaml"

    ```yaml
    --8<-- "content/build/entitled/build-run.yaml
    ```

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}build-run.yaml
    ```

# Additional resources

* <https://shipwright.io/>
