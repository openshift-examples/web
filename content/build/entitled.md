---
title: Entitled builds on OpenShift 4
linktitle: Entitled
weight: 5200
description: TBD
tags:
  - entitlement
  - build
---
# Entitled builds and OpenShift 4

With entitled builds, we have to cover two main topics:

  1. How to get the entitlement and refresh the entitlement

  2. How to provide/attach the entitlement to the build.


## Let’s elaborate on the first one: How to get the entitlement.

Technically, the entitlement is a certificate to get access to specific Red Hat Enterprise Linux content and have to refresh regularly. Red Hat introduce [Simple Content Access](https://access.redhat.com/documentation/en-us/subscription_central/2021/html/getting_started_with_simple_content_access/index) to simplify the access, for example for container builds.

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
```
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


## Let’s elaborate on the second one: How to provide/attach the entitlement to the build.

There are three options to attach the entitlement to a build – build pod at the end:

  1. Simple attaches a secret with the entitlement to the build.
     Documentation: [Adding subscription entitlements as a build secret](https://docs.openshift.com/container-platform/4.11/cicd/builds/running-entitled-builds.html#builds-source-secrets-entitlements_running-entitled-builds)

  2. Leverage the [Shared Resource CSI Driver Operator](https://docs.openshift.com/container-platform/4.11/storage/container_storage_interface/ephemeral-storage-shared-resource-csi-driver-operator.html)    (Technology Preview) to share the etc-pki-entitlement secrets from openshift-config-managed namespace provided by the Insights Operator.

  3. Rollout entitlement cluster-wide via MachineConfigOperator.
     Not recommend because it changes every single build behavior in the OpenShift Cluster, additional you have to update the MachineConfig to the new entitlement regularly.

### Let’s take a more in-depth look at the Shared Resource CSI solution:

First enable the Shared Resource CSI Driver Operator via FeatureGates:

  * [Enabling feature sets using the web console](https://docs.openshift.com/container-platform/4.11/nodes/clusters/nodes-cluster-enabling-features.html#nodes-cluster-enabling-features-console_nodes-cluster-enabling)

  * [Enabling feature sets using the CLI](https://docs.openshift.com/container-platform/4.11/nodes/clusters/nodes-cluster-enabling-features.html#nodes-cluster-enabling-features-console_nodes-cluster-enabling)

Then wait for the MachineConfigPool is updated and shared resources objects are available:

```bash
$  oc api-resources | grep  sharedresource
Sharedconfigmaps  sharedresource.openshift.io/v1alpha1 false SharedConfigMap
Sharedsecrets     sharedresource.openshift.io/v1alpha1 false SharedSecret
```

#### Create an sharedsecrets object (cluster scoped):

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}etc-pki-entitlement.SharedSecret.yaml
    ```

=== "etc-pki-entitlement.SharedSecret.yaml"

    ```yaml
    --8<-- "content/build/entitled/etc-pki-entitlement.SharedSecret.yaml"
    ```


#### Create a project/namespace

=== "OC"

    ```bash
    oc create project entitled-build-demo
    ```


#### Grant access to SharedSecret `etc-pki-entitlement`

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}etc-pki-entitlement.Role.yaml
    oc apply -f {{ page.canonical_url }}etc-pki-entitlement.RoleBinding.yaml
    ```

=== "etc-pki-entitlement.SharedSecret.yaml"

    ```yaml
    ---
    --8<-- "content/build/entitled/etc-pki-entitlement.Role.yaml"
    ---
    --8<-- "content/build/entitled/etc-pki-entitlement.RoleBinding.yaml"
    ```


#### Create ImageStream and BuildConfig with access to entitlement


=== "etc-pki-entitlement.SharedSecret.yaml"

    ```yaml hl_lines="28-38"
    ---
    --8<-- "content/build/entitled/etc-pki-entitlement.ImageStream.yaml"
    ---
    --8<-- "content/build/entitled/etc-pki-entitlement.BuildConfig.yaml"
    ```

=== "OC"

    ```bash
    oc apply -f {{ page.canonical_url }}etc-pki-entitlement.ImageStream.yaml
    oc apply -f {{ page.canonical_url }}etc-pki-entitlement.BuildConfig.yaml
    ```



Additional Resources

  * <https://cloud.redhat.com/blog/how-to-build-images-with-rhel-subscriptions-on-openshift>
  * <https://cloud.redhat.com/blog/the-path-to-improving-the-experience-with-rhel-entitlements-on-openshift>
  * <https://github.com/openshift/enhancements/blob/master/enhancements/subscription-content/subscription-injection.md>
  * <https://issues.redhat.com/browse/OCPBU-141>

