---
title: Air-gapped/Disconnected
linktitle: Air-gapped/Disconnected
description: Some informations around OLM and Air-gapped/Disconnected
tags: ['OLM','air-gapped','v4.17','v4.18','v4.19','operators']
---
# Air-gapped/Disconnected

* Support Sparse Manifests <https://issues.redhat.com/browse/OCPSTRAT-1808>

## ImageSetConfiguration examples (oc mirror v2)

**Syncronize only the latest version of the Operator!!**

```yaml
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    packages:
      - name: kubevirt-hyperconverged
        channels:
        - name: stable
```

**Recommended add a minVersion is sync from minVersion all newer versions!**

```yaml
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
    packages:
      - name: kubevirt-hyperconverged
        channels:
        - name: stable
          minVersion: v4.17.4
```

More usefull examples: <https://github.com/openshift/oc-mirror/tree/main/docs/examples>

## Operator upgrade stuck

### Check the available versions in your index

For example 4.17.4 is installed, there a missing versions to get to 4.17.11. Because 4.17.11 just replace 4.17.7.

```shell
# oc mirror list operators --catalog mirror-registry.disco.coe.muc.redhat.com:5000/disco/redhat/redhat-operator-index:v4.17 --package kubevirt-hyperconverged --channel stable                            [192/192]
W0711 07:07:20.497749  129134 mirror.go:86]

⚠️  oc-mirror v1 is deprecated (starting in 4.18 release) and will be removed in a future release - please migrate to oc-mirror --v2
VERSIONS
4.17.11
```

```shell
# oc mirror list operators --catalog mirror-registry.disco.coe.muc.redhat.com:5000/disco/redhat/redhat-operator-index:v4.17 --package kubevirt-hyperconverged --channel stable
W0711 07:52:14.847377  129286 mirror.go:86]

⚠️  oc-mirror v1 is deprecated (starting in 4.18 release) and will be removed in a future release - please migrate to oc-mirror --v2
VERSIONS
4.17.11
4.17.4
4.17.5
4.17.7
```

```shell
podman run -ti --rm --entrypoint cat mirror-registry.disco.coe.muc.redhat.com:5000/disco/redhat/redhat-operator-index:v4.17   /configs/kubevirt-hyperconverged/catalog.json | jq -r 'select(.schema=="olm.channel")' | jq
{
  "schema": "olm.channel",
  "name": "stable",
  "package": "kubevirt-hyperconverged",
  "entries": [
    {
      "name": "kubevirt-hyperconverged-operator.v4.17.4",
      "replaces": "kubevirt-hyperconverged-operator.v4.17.3",
      "skipRange": ">=4.16.6 <4.17.0"
    },
    {
      "name": "kubevirt-hyperconverged-operator.v4.17.5",
      "replaces": "kubevirt-hyperconverged-operator.v4.17.4",
      "skipRange": ">=4.16.6 <4.17.0"
    },
    {
      "name": "kubevirt-hyperconverged-operator.v4.17.7",
      "replaces": "kubevirt-hyperconverged-operator.v4.17.5",
      "skipRange": ">=4.16.6 <4.17.0"
    },
    {
      "name": "kubevirt-hyperconverged-operator.v4.17.11",
      "replaces": "kubevirt-hyperconverged-operator.v4.17.7",
      "skipRange": ">=4.16.7 <4.17.0"
    }
  ]
}
```

```shell
grpcurl -plaintext  localhost:50051 api.Registry/ListBundles | jq '{"packageName","replaces","version","skipRange","csvName","channel"} | select(.packageName=="kubevirt-hyperconverged") '
{
  "packageName": "kubevirt-hyperconverged",
  "replaces": "kubevirt-hyperconverged-operator.v4.17.7",
  "version": "4.17.11",
  "skipRange": ">=4.16.7 <4.17.0",
  "csvName": "kubevirt-hyperconverged-operator.v4.17.11",
  "channel": null
}
{
  "packageName": "kubevirt-hyperconverged",
  "replaces": "kubevirt-hyperconverged-operator.v4.17.3",
  "version": "4.17.4",
  "skipRange": ">=4.16.6 <4.17.0",
  "csvName": "kubevirt-hyperconverged-operator.v4.17.4",
  "channel": null
}
{
  "packageName": "kubevirt-hyperconverged",
  "replaces": "kubevirt-hyperconverged-operator.v4.17.4",
  "version": "4.17.5",
  "skipRange": ">=4.16.6 <4.17.0",
  "csvName": "kubevirt-hyperconverged-operator.v4.17.5",
  "channel": null
}
{
  "packageName": "kubevirt-hyperconverged",
  "replaces": "kubevirt-hyperconverged-operator.v4.17.5",
  "version": "4.17.7",
  "skipRange": ">=4.16.6 <4.17.0",
  "csvName": "kubevirt-hyperconverged-operator.v4.17.7",
  "channel": null
}
```

#### Visulize version graph

* Download opm tool: <https://github.com/operator-framework/operator-registry>

Minimum `~/.config/containers/policy.json`

```json
{
    "default": [{"type": "insecureAcceptAnything"}]
}
```

```shell
cat << EOF > ./mermaid.json
{ "maxTextSize": 300000 }
EOF

opm alpha render-graph -p kubevirt-hyperconverged mirror-registry.disco.coe.muc.redhat.com:5000/disco/redhat/redhat-operator-index:v4.17 | podman run --rm -i -v "$PWD":/data ghcr.io/mermaid-js/mermaid-cli/mermaid-cli -c /data/mermaid.json -o /data/operatorhubio-catalog.svg
```

![Image title](operatorhubio-catalog.svg)

### `constraints not satisfiable: subscription....`

Try:

```shell
oc delete pods -n openshift-operator-lifecycle-manager -l app=catalog-operator
oc delete pods -n openshift-operator-lifecycle-manager -l app=olm-operator
```

## Discover the operator index

### via oc mirror

```shell
# oc mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.18
NAME                                            DISPLAY NAME  DEFAULT CHANNEL
3scale-operator                                               threescale-2.15
advanced-cluster-management                                   release-2.13
amq-broker-rhel8                                              7.12.x
amq-broker-rhel9                                              7.13.x
amq-online                                                    stable
amq-streams                                                   stable
amq-streams-console                                           alpha
amq7-interconnect-operator                                    1.10.x
ansible-automation-platform-operator                          stable-2.5
...

# oc mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.18 --package kubevirt-hyperconverged
W0711 09:40:18.654683  130182 mirror.go:86]

   oc-mirror v1 is deprecated (starting in 4.18 release) and will be removed in a future release - please migrate to oc-mirror --v2

NAME                     DISPLAY NAME  DEFAULT CHANNEL
kubevirt-hyperconverged                stable

PACKAGE                  CHANNEL      HEAD
kubevirt-hyperconverged  candidate    kubevirt-hyperconverged-operator.v4.18.9
kubevirt-hyperconverged  dev-preview  kubevirt-hyperconverged-operator.v4.99.0-0.1723448771
kubevirt-hyperconverged  stable       kubevirt-hyperconverged-operator.v4.18.8
[coe@bastion mirror]$ oc mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.18 --package kubevirt-hyperconverged --channel stable
W0711 09:44:44.362761  130240 mirror.go:86]

⚠️  oc-mirror v1 is deprecated (starting in 4.18 release) and will be removed in a future release - please migrate to oc-mirror --v2

VERSIONS
4.12.2
4.13.2
4.14.3
4.15.2
4.17.4
4.18.2
4.16.0
4.18.8
4.12.1
4.14.1
4.17.0
4.14.0
4.14.2
4.15.0
4.16.1
4.13.1
4.16.2
4.17.2
4.18.0
4.12.0
4.16.3
4.13.3
4.13.4
4.15.1
4.17.1
4.18.1
4.13.0
4.17.3
4.18.3
```

### via grpcurl

* grpcurl is available here <https://github.com/fullstorydev/grpcurl>
* <https://github.com/operator-framework/operator-registry#using-the-catalog-locally>

Start index images:

```shell
podman run -p 50051:50051 -ti --rm   registry.redhat.io/redhat/redhat-operator-index:v4.18
```

And dicover

```shell
# grpcurl -plaintext localhost:50051 api.Registry/ListPackages | jq -r '.name'
kubevirt-hyperconverged
...

# grpcurl -plaintext -d '{"name":"rhods-operator"}' localhost:50051 api.Registry/GetPackage
{
  "name": "kubevirt-hyperconverged",
  "channels": [
    {
      "name": "stable",
      "csvName": "kubevirt-hyperconverged-operator.v4.17.11"
    }
  ],
  "defaultChannelName": "stable"
}

# grpcurl -plaintext  localhost:50051 api.Registry/ListBundles | jq '{"packageName","replaces","version","skipRange","csvName","channel"} | select(.packageName=="kubevirt-hyperconverged")'
grpcurl -plaintext  localhost:50051 api.Registry/ListBundles | jq '{"packageName","replaces","version","skipRange","csvName","channel"} | select(.packageName=="kubevirt-hyperconverged")'
{
  "packageName": "kubevirt-hyperconverged",
  "replaces": "kubevirt-hyperconverged-operator.v4.18.2",
  "version": "4.18.3",
  "skipRange": null,
  "csvName": "kubevirt-hyperconverged-operator.v4.18.3",
  "channel": null
}
{
  "packageName": "kubevirt-hyperconverged",
  "replaces": "kubevirt-hyperconverged-operator.v4.18.3",
  "version": "4.18.4",
  "skipRange": null,
  "csvName": "kubevirt-hyperconverged-operator.v4.18.4",
  "channel": null
}
...
```

#### Discover grpcurl api

```shell
# grpcurl -plaintext localhost:50051 list api.Registry
api.Registry.GetBundle
api.Registry.GetBundleForChannel
api.Registry.GetBundleThatReplaces
api.Registry.GetChannelEntriesThatProvide
api.Registry.GetChannelEntriesThatReplace
api.Registry.GetDefaultBundleThatProvides
api.Registry.GetLatestChannelEntriesThatProvide
api.Registry.GetPackage
api.Registry.ListBundles
api.Registry.ListPackages

# grpcurl -plaintext localhost:50051 describe api.Registry.GetBundle
api.Registry.GetBundle is a method:
rpc GetBundle ( .api.GetBundleRequest ) returns ( .api.Bundle );

# grpcurl -plaintext localhost:50051 describe .api.GetBundleRequest

api.GetBundleRequest is a message:
message GetBundleRequest {
  string pkgName = 1;
  string channelName = 2;
  string csvName = 3;
}

# grpcurl -plaintext -d '{"csvName": "update-service-operator.v5.0.3","pkgName": "cincinnati-operator","channelName": "v1"}' localhost:50051 api.Registry/GetBundle | jq '{"packageName","replaces","version","skipRange","csvName","channel"}'
{
  "packageName": "cincinnati-operator",
  "replaces": null,
  "version": "5.0.3",
  "skipRange": null,
  "csvName": "update-service-operator.v5.0.3",
  "channel": null
}
```
