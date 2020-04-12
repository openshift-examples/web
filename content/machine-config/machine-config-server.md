# Machine Config

#### Create MachineConfig

```yaml
oc create -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: mypool
  name: 00-mypool
spec:
  config:
    ignition:
      config: {}
      security:
        tls: {}
      timeouts: {}
      version: 2.2.0
    networkd: {}
    passwd: {}
    storage: {}
  fips: false
  kernelArguments: null
  osImageURL: quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:db2b9ac6cd5ae6eb30b1b2c5f9739734edc7b628862072fb7399b4377684265b
EOF
```

#### Create MachineConfigPool

```yaml
oc create -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: mypool
spec:
  configuration:
    name: rendered-mypool
    source:
    - apiVersion: machineconfiguration.openshift.io/v1
      kind: MachineConfig
      name: mypool
  machineConfigSelector:
    matchLabels:
      machineconfiguration.openshift.io/role: mypool
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/mypool: ""
  paused: false
EOF
```

#### Result

```text
root@homer:~ $ curl -i  -k https://192.168.51.1:22623/config/mypool
HTTP/1.1 200 OK
Content-Length: 8823
Content-Type: application/json
Date: Tue, 29 Oct 2019 15:55:35 GMT

{"ignition":{"config":{.......
```

