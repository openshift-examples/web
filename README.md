# OpenShift examples

| Example  |  |
| ------------- | ------------- |
| EAP / JBoss Clustering (Session replication)  | See [eap-cluster/README.md](eap-cluster/README.md)  |
| Autoscaling & SpringBoot | See [autoscaling/README.md](autoscaling/README.md)  |
| initContainers - DNS & TCP Check | [initContainers.md.md](initContainers.md)  |

# Run OCP on your laptop
```
oc cluster up --image=registry.access.redhat.com/openshift3/ose --version=v3.5.5.31-2 --public-hostname=localhost
```
