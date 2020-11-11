# Air-gapped OperatorHub - pre 4.6

!!! warning
    Please mirror with `--filter-by-os='.*'` because of
    [BZ 1890951](https://bugzilla.redhat.com/show_bug.cgi?id=1890951)


## Resources

 * [Using Operator Lifecycle Manager on restricted networks](https://docs.openshift.com/container-platform/4.5/operators/admin/olm-restricted-networks.html)

## Prerequisite

* [Creating a mirror registry for installation in a restricted network](https://docs.openshift.com/container-platform/4.5/installing/install_config/installing-restricted-networks-preparations.html#installing-restricted-networks-preparations)


**All examples use the environment variables of the official document**

```bash
export OCP_RELEASE=$(oc version -o json  --client | jq -r '.releaseClientVersion')
export LOCAL_REGISTRY='host.compute.local:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='/root/hetzner-ocp4/pullsecret.json'
export RELEASE_NAME="ocp-release"
export ARCHITECTURE=x86_64
# Additional to create uniq names
export SERIAL=$(date +%s)
# optional but usefull, export KUBECONFIG or run oc login
export KUBECONFIG='/root/hetzner-ocp4/air-gapped/auth/kubeconfig'
```

## Red Hat Operators

```bash

oc adm catalog build \
  --appregistry-org redhat-operators \
  --to=${LOCAL_REGISTRY}/olm/redhat-operators:${SERIAL} \
  --from=registry.redhat.io/openshift4/ose-operator-registry:v4.5 \
  -a ${LOCAL_SECRET_JSON} 2>&1 | tee redhat-operators.build.${SERIAL}.log

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-redhat-operators-${SERIAL}
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: ${LOCAL_REGISTRY}/olm/redhat-operators:${SERIAL}
  displayName: My Red Hat Catalog
  publisher: me
EOF

oc adm catalog mirror \
  ${LOCAL_REGISTRY}/olm/redhat-operators:${SERIAL} \
  ${LOCAL_REGISTRY} \
  --to-manifests=redhat-operators-${SERIAL} \
  -a ${LOCAL_SECRET_JSON} 2>&1 | tee redhat-operators.mirror.${SERIAL}.log

```

## Certified Operators

```bash
oc adm catalog build \
  --appregistry-org certified-operators \
  --from=registry.redhat.io/openshift4/ose-operator-registry:v4.5 \
  --to=${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL} \
  -a ${LOCAL_SECRET_JSON} 2>&1 | tee certified-operators.build.${SERIAL}.log

oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-certified-operators-${SERIAL}
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: ${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL}
  displayName: My Red Hat Catalog ${SERIAL}
  publisher: grpc
EOF

oc adm catalog mirror \
  ${LOCAL_REGISTRY}/olm/certified-operators:${SERIAL} \
  ${LOCAL_REGISTRY} \
  --to-manifests=certified-operators-${SERIAL} \
  -a ${LOCAL_SECRET_JSON} 2>&1 | tee certified-operators.mirror.${SERIAL}.log

```

## Debugging

### Check pods of catalog source

```bash
$ oc get pods -n openshift-marketplace
NAME                        READY   STATUS    RESTARTS   AGE
my-redhat-operators-lz5gb   1/1     Running   0          74s
...

$ oc logs -n openshift-marketplace -l olm.catalogSource=my-redhat-operators-${SERIAL}
time="2020-10-21T15:02:21Z" level=info msg="serving registry" database=/bundles.db port=50051

$ oc logs -n openshift-marketplace -l olm.catalogSource=my-certified-operators-${SERIAL}
time="2020-10-21T15:12:29Z" level=info msg="serving registry" database=/bundles.db port=50051
```

### Check packagemanifests

```bash
$ oc get packagemanifests -l catalog=my-redhat-operators-${SERIAL} | wc -l
51

$ oc get packagemanifests -l catalog=my-certified-operators-${SERIAL} | wc -l
No resources found in openshift-marketplace namespace.
0
```

### Check with grpcurl

##### Mirror container image:
```bash
oc image mirror \
  quay.io/openshift-examples/toolbox:latest \
  ${LOCAL_REGISTRY}/openshift-examples/toolbox:latest \
  -a=${LOCAL_SECRET_JSON}
```
##### Start grpcurl pod:
```bash
oc apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: toolbox
spec:
  containers:
    - name: toolbox
      image: ${LOCAL_REGISTRY}/openshift-examples/toolbox:latest
  restartPolicy: Never
EOF
```

##### Run grpcurl

More grpcurl examples: https://github.com/operator-framework/operator-registry#using-the-catalog-locally

```bash
$ oc get svc
NAME                           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
marketplace-operator-metrics   ClusterIP   172.30.114.130   <none>        8383/TCP,8081/TCP   8h
my-certified-operators         ClusterIP   172.30.80.29     <none>        50051/TCP           52m
my-redhat-operators            ClusterIP   172.30.152.240   <none>        50051/TCP           64m

$ oc rsh toolbox
sh-4.4# grpcurl -plaintext my-certified-operators:50051 api.Registry/ListPackages  | wc -l
423
sh-4.4# grpcurl -plaintext my-redhat-operators:50051 api.Registry/ListPackages  | wc -l
150
sh-4.4# grpcurl -plaintext my-certified-operators:50051 api.Registry/ListPackages | grep -i dell
  "name": "dell-csi-operator-certified"
sh-4.4# grpcurl -plaintext -d '{"name":"dell-csi-operator-certified"}' my-certified-operators:50051 api.Registry/GetPackage
{
  "name": "dell-csi-operator-certified",
  "channels": [
    {
      "name": "stable",
      "csvName": "dell-csi-operator.v1.1.0"
    }
  ],
  "defaultChannelName": "stable"
}
sh-4.4# grpcurl -plaintext my-redhat-operators:50051 api.Registry/ListPackages | grep logg
  "name": "cluster-logging"
sh-4.4# grpcurl -plaintext -d '{"name":"cluster-logging"}' my-redhat-operators:50051 api.Registry/GetPackage
{
  "name": "cluster-logging",
  "channels": [
    {
      "name": "4.2",
      "csvName": "clusterlogging.4.2.36-202006230600.p0"
    },
    {
      "name": "4.2-s390x",
      "csvName": "clusterlogging.4.2.36-202006230600.p0-s390x"
    },
    {
      "name": "4.3",
      "csvName": "clusterlogging.4.3.40-202010141211.p0"
    },
    {
      "name": "4.4",
      "csvName": "clusterlogging.4.4.0-202009161309.p0"
    },
    {
      "name": "4.5",
      "csvName": "clusterlogging.4.5.0-202010090328.p0"
    },
    {
      "name": "preview",
      "csvName": "clusterlogging.4.1.41-202004130646"
    }
  ],
  "defaultChannelName": "4.5"
}
```



### Check packageserver

The package manager actually sync from grpc andpoint to packagemanifest objects.

```bash

$ oc project openshift-operator-lifecycle-manager

$ oc get pods -l app=packageserver
NAME                            READY   STATUS    RESTARTS   AGE
packageserver-b56594947-cwtjr   1/1     Running   1          8h
packageserver-b56594947-v787m   1/1     Running   1          8h

$ oc logs packageserver-b56594947-v787m | grep error | tail
time="2020-10-21T16:26:18Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=alpha error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=stable error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=stable error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=6.0.6 error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=preview error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=production error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:26:18Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
$ oc logs packageserver-b56594947-cwtjr | grep error | tail
time="2020-10-21T16:24:24Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=namespaced error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=alpha error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=stable error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=production error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="error getting bundle, eliding channel" action="refresh cache" channel=v1.2 error="rpc error: code = Unknown desc = no such column: api_provider.channel_entry_id" source="{my-certified-operators openshift-marketplace}"
time="2020-10-21T16:24:24Z" level=warning msg="eliding package: error converting to packagemanifest" action="refresh cache" err="packagemanifest has no valid channels" source="{my-certified-operators openshift-marketplace}"
$
```
