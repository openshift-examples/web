# Networking

## Create bridge on main interface

```yaml
oc apply -f - <<EOF
apiVersion: nmstate.io/v1alpha1 
kind: NodeNetworkConfigurationPolicy 
metadata: 
  name: br1-ens3-policy-workers 
spec: 
  nodeSelector: 
    node-role.kubernetes.io/worker: "" 
  desiredState: 
    interfaces: 
      - name: br1 
        description: Linux bridge with ens3 as a port 
        type: linux-bridge 
        state: up 
        ipv4: 
          enabled: false 
        bridge: 
          options: 
            stp: 
              enabled: false 
          port: 
            - name: ens3
EOF
```

## Create Network Attachment Definition

```yaml
cat << EOF | oc apply -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: tuning-bridge-fixed
  annotations:
    k8s.v1.cni.cncf.io/resourceName: bridge.network.kubevirt.io/br1
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "br1",
    "plugins": [
      {
        "type": "cnv-bridge",
        "bridge": "br1"
      },
      {
        "type": "cnv-tuning"
      }
    ]
  }'
EOF
```
