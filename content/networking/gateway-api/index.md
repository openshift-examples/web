---
title: Gateway API
linktitle: Gateway API
description: Gateway API examples on OpenShift — GatewayClass, Gateway with External DNS, HTTPRoute, and re-encrypt termination with BackendTLSPolicy.
tags: ['Gateway API','v4.22','networking']
---
# Gateway API

The Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) is the [next generation](https://gateway-api.sigs.k8s.io/docs/) of Kubernetes Ingress, Load Balancing, and Service Mesh APIs — intended as a more expressive, role-oriented successor to `Ingress` and OpenShift `Route` objects.
It separates concerns across three roles:

| Role | Resource | Who manages it |
|---|---|---|
| Infrastructure Provider | `GatewayClass` | Cluster admin / cloud provider |
| Cluster Operator | `Gateway` | Platform team |
| Application Developer | `HTTPRoute` / `GRPCRoute` / … | App team |

![Gateway API resource model](resource-model.png)

Official documentation:

* [OpenShift — Gateway API](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/networking/gateway-api) — including how to enable Gateway API on your cluster
* [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)

!!! tip "Red Hat Connectivity Link Tutorial"

    For a full end-to-end walkthrough covering TLS automation, OIDC auth, rate limiting, and observability on top of Gateway API, check out Nikolaus Lemberski's
    [Connectivity Link 1.3 Tutorial](https://github.com/nikolaus-lemberski/connectivity-link-tutorial).
    It uses [Red Hat Connectivity Link](https://docs.redhat.com/en/documentation/red_hat_connectivity_link/1.3/) (based on [Kuadrant](https://kuadrant.io/)) to add `TLSPolicy`, `AuthPolicy`, and `RateLimitPolicy` on top of the Gateway API resources shown on this page.

Tested with:

| Component | Version |
|---|---|
| OpenShift | v4.22.5 |

## Create `GatewayClass`

```yaml title="GatewayClass"
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: openshift-default
spec:
  controllerName: openshift.io/gateway-controller/v1
```

## Create `Gateway`

!!! warning "Requires `LoadBalancer` service support"

    Creating a Gateway provisions a Kubernetes service of type `LoadBalancer`.
    On-premise clusters need MetalLB installed and configured — see
    [On-premise gateway routing requirements](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/ingress_and_load_balancing/configuring-gateway-api#on-premise-gateway-routing-requirements_assigning-network-addresses-gateways).

    [RFE-8640 — "Support self-provisioned load balancers for Gateway API"](https://redhat.atlassian.net/browse/RFE-8640)

Create a TLS secret for the Gateway:

```shell title="Create TLS secret"
oc create secret tls gwapidefault-cert \
    -n openshift-ingress \
    --cert=cert_and_intermediate.pem \
    --key=cert-key.pem
```

=== "gateway.yaml"

    ```yaml hl_lines="18"
    --8<-- "content/networking/gateway-api/gateway.yaml"
    ```

=== "Download/Apply: gateway.yaml"

    ```shell
    curl -L -O {{ page.canonical_url }}gateway.yaml
    ```

    ```shell
    oc apply -f {{ page.canonical_url }}gateway.yaml
    ```

### DNS setup

The wildcard hostname defined in the Gateway must have a DNS A record pointing to the external IP of the LoadBalancer service:

```shell title="Verify Gateway and services"
% oc get gateway,svc -n openshift-ingress
NAME                                        CLASS               ADDRESS         PROGRAMMED   AGE
gateway.gateway.networking.k8s.io/default   openshift-default   10.32.105.107   True         4d6h

NAME                                TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                                      AGE
service/default-openshift-default   LoadBalancer   172.30.169.90   10.32.105.107   15021:30288/TCP,80:31988/TCP,443:32360/TCP   3d23h
service/istiod-openshift-gateway    ClusterIP      172.30.3.90     <none>          15010/TCP,15012/TCP,443/TCP,15014/TCP        4d18h
service/router-internal-default     ClusterIP      172.30.22.81    <none>          80/TCP,443/TCP,1936/TCP                      12d
```

If you use the [External DNS Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/networking_operators/external-dns-operator-1), the LoadBalancer service already carries the annotation for automatic DNS provisioning:

```shell title="External DNS annotation" hl_lines="4"
% oc get svc/default-openshift-default -n openshift-ingress -o yaml
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: '*.gwapi-default.ocp7.stormshift.coe.muc.redhat.com'
```

Otherwise, create the DNS record manually:

```txt
*.gwapi-default.ocp7 IN A 10.32.105.107
```

See also: [Configuring DNS for on-premise gateways](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/ingress_and_load_balancing/configuring-gateway-api#configuring-dns-on-premise-gateways_assigning-network-addresses-gateways)

## Basic HTTPRoute example

Exposes a simple workload through the `Gateway` via an `HTTPRoute`.

### Deploy the workload

```shell
oc apply -k 'https://github.com/openshift-examples/kustomize.git/components/simple-https?ref=2026-07-20'
```

### Attach an HTTPRoute

=== "httproute.yaml"

    ```yaml
    --8<-- "content/networking/gateway-api/httproute.yaml"
    ```

=== "Download: httproute.yaml"

    ```shell
    curl -L -O {{ page.canonical_url }}httproute.yaml
    ```

```shell
oc apply -f httproute.yaml
```

Verify the route is `Accepted`:

```shell
% oc get httproute -n test-app
NAME           HOSTNAMES                                                           AGE
simple-https   ["simple-https.gwapi-default.ocp7.stormshift.coe.muc.redhat.com"]   3h27m
```

```shell title="Test edge termination"
% curl https://simple-https.gwapi-default.ocp7.stormshift.coe.muc.redhat.com/
<html>
<head></head>
<body>
<h1>Hi, 10.131.0.20</h1>
I'm a simple httpd+CGI webserver running in
pod <b>simple-https-79f5d5876b-w6vtf</b> on node <b>ocp7-worker-0</b>
responding at 2026-07-20 19:14:33 +0000
via <b>http</b>
</body>
</html>
```

Both HTTP and HTTPS work, but the backend always responds via plain HTTP — the Gateway terminates TLS and forwards unencrypted traffic to the pod.

![Connection flow — edge termination](overview.drawio){page=Page-1}

## Re-encrypt termination with `BackendTLSPolicy`

To encrypt traffic between the Gateway and the backend, use a `BackendTLSPolicy`.

See: [Configuring re-encrypt termination with a BackendTLSPolicy](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/ingress_and_load_balancing/configuring-gateway-api#configuring-backend-reencrypt-tls_securing-httproutes)

### Known limitation: CA certificate key name mismatch

The `BackendTLSPolicy` spec requires the CA certificate in a ConfigMap key named exactly **`ca.crt`**. OpenShift's service-ca operator injects certificates with key `service-ca.crt`, and the trusted CA bundle injector uses `ca-bundle.crt`. Neither matches what `BackendTLSPolicy` expects.

??? quote "Tracking issues and proposed solutions"

    **Active RFEs / Tracking Issues**

    - [RFE-9174](https://redhat.atlassian.net/browse/RFE-9174) — "CA Bundle Key Name Flexibility" — Approved, Priority: Critical. Primary RFE requesting configurable CA bundle key names for interop between OpenShift CA injection and `BackendTLSPolicy`.
    - [OCPSTRAT-3459](https://redhat.atlassian.net/browse/OCPSTRAT-3459) — "CA Bundle Key Name Flexibility" — New, Priority: Critical. Strategic tracking issue under Networking, created July 2026.
    - [RFE-8361](https://redhat.atlassian.net/browse/RFE-8361) — "Setting the Gateway API controller to mount openshift-service-ca.crt" — Backlog. Original customer-filed RFE from October 2025.
    - [gateway-api#4196](https://github.com/kubernetes-sigs/gateway-api/issues/4196) — Upstream feature request to support custom certificate key names.

    **Potential solutions being evaluated (from OCPSTRAT-3459)**

    1. **Upstream Gateway API change** — Allow the gateway controller to accept a configurable key name
    2. **Add service CA to the default trust bundle** — No per-resource configuration needed
    3. **Use `ClusterTrustBundle`** — Newer Kubernetes API, requires k8s 1.37+
    4. **Fallback-to-first-cert-in-configmap** — Gateway controller uses the first certificate found regardless of key name
    5. **OpenShift service-ca-operator change** — Allow configuring the injected key name so it can inject as `ca.crt`

### Workaround: create a ConfigMap with the correct key

Create a ConfigMap that copies the service CA content into a key named `ca.crt`:

```shell
oc get configmap openshift-service-ca.crt -n <namespace> -o jsonpath='{.data.service-ca\.crt}' \
  | oc create configmap my-openshift-service-ca.crt -n <namespace> --from-file=ca.crt=/dev/stdin
```

!!! warning

    This ConfigMap will **not** auto-rotate when the service CA is renewed.
    You need external tooling (custom controller, CronJob, or GitOps template) to keep it in sync.
    Watch out for x509 formatting issues — trailing newlines or whitespace can cause certificate validation failures.

### Apply the `BackendTLSPolicy`

=== "backendtlspolicy.yaml"

    ```yaml
    --8<-- "content/networking/gateway-api/backendtlspolicy.yaml"
    ```

=== "Download: backendtlspolicy.yaml"

    ```shell
    curl -L -O {{ page.canonical_url }}backendtlspolicy.yaml
    ```

```shell
oc apply -f backendtlspolicy.yaml
```

### Update the HTTPRoute for HTTPS backend

Change the backend port from `8080` to `8443`:

```yaml title="HTTPRoute" hl_lines="17"
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: simple-https
spec:
  parentRefs:
    - kind: Gateway
      name: default
      namespace: openshift-ingress
  hostnames:
    - "simple-https.gwapi-default.ocp7.stormshift.coe.muc.redhat.com"
  rules:
    - backendRefs:
        - group: ""
          kind: Service
          name: simple-https
          port: 8443
```

```shell title="Test re-encrypt termination"
% curl https://simple-https.gwapi-default.ocp7.stormshift.coe.muc.redhat.com/
<html>
<head></head>
<body>
<h1>Hi, 10.128.2.98</h1>
I'm a simple httpd+CGI webserver running in
pod <b>simple-https-79f5d5876b-s276h</b> on node <b>ocp7-worker-1</b>
responding at 2026-07-21 14:14:18 +0000
via <b>https</b>
</body>
</html>
```

HTTPS work, and the backend always responds via HTTPS — the Gateway terminates TLS and forwards encrypted traffic to the pod.

![Connection flow — re-encrypt termination](overview.drawio){page=Page-2}

## Troubleshooting

### Dump Envoy config

```shell
oc rsh deployment/default-openshift-default pilot-agent request GET /config_dump > default-openshift-default.json
```

### Dump all endpoints

Forward the Envoy admin port:

```shell
oc port-forward deployment/default-openshift-default 15000:15000
```

List endpoints (filtered by namespace):

```shell title="List endpoints"
% curl -s 'http://localhost:15000/config_dump?include_eds' | jq -r '
    .configs[]
    | select(.["@type"]
    | contains("EndpointsConfigDump"))
    | .dynamic_endpoint_configs[]
    | .endpoint_config
    | .cluster_name as $cn
    | .endpoints[]?.lb_endpoints[]?.endpoint.address.socket_address
    | "\($cn) \(.address):\(.port_value)"
    ' | grep test-app
outbound|8080||simple-https.test-app.svc.cluster.local 10.128.2.99:8080
outbound|8080||simple-https.test-app.svc.cluster.local 10.131.0.24:8080
outbound|8443||simple-https.test-app.svc.cluster.local 10.128.2.99:8443
outbound|8443||simple-https.test-app.svc.cluster.local 10.131.0.24:8443
```

Filter by a specific cluster name:

```shell title="Filter by cluster name"
% curl -s 'http://localhost:15000/config_dump?include_eds' | jq -r '
    .configs[]
    | select(.["@type"] | contains("EndpointsConfigDump"))
    | .dynamic_endpoint_configs[]
    | .endpoint_config
    | select(.cluster_name | contains("demo-backend"))
    | .cluster_name as $cn
    | .endpoints[]?.lb_endpoints[]?.endpoint.address.socket_address
    | "\($cn) \(.address):\(.port_value)"'
```

