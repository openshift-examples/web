# OpenShift examples

| Example  |  |
| ------------- | ------------- |
| EAP / JBoss Clustering (Session replication)  | See [eap-cluster/README.md](eap-cluster/README.md)  |
| Autoscaling & SpringBoot | See [autoscaling/README.md](autoscaling/README.md)  |
| initContainers - DNS & TCP Check | [initContainers.md](initContainers.md)  |
| Build (chaining build...) | [build/README.md](build/README.md)  |
| OpsContainer DaemonSet | oc create -f [ops-container-example.yml](ops-container-example.yml) |

# Run OCP on your laptop
```
oc cluster up --image=registry.access.redhat.com/openshift3/ose --version=v3.5.5.31-2 --public-hostname=localhost
```
