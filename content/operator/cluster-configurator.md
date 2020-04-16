# How to apply your initial cluster configuration with OpenShift 4 ?

It is quite easy to deploy your OpenShift 4 cluster, if you don't know how easy it is check out the blog post: [OpenShift 4: Install Experience](https://blog.openshift.com/openshift-4-install-experience/)

To be honest, after the installation there are some customer-specific configurations, for examples authentication, custom certificates,you have to do. If you want to re-deploy on several clusters and save these changes no your Git repository, here are two posible ways to solve them.

## 1) Add your changes at installation time

### Create cluster manifest

```bash
openshift-install create manifests --dir=conf
```

### Add your additional configurations

#### For example, add htpasswd authentication

##### Create htpasswd secret

```bash
cat > conf/openshift/99_openshift-auth_htpasswd-secret.yaml << EOF
apiVersion: v1
data:
    htpasswd: dXNlcjE6JGFwcjEkejRVdE5ZczgkYjVmMzBIWkR1MHNaOTFCNzIuYXQ3LwoKYWRtaW46JGFwcjEkNkpQOS95eXUkTWZjSlRPU3hqMzRFWTNKYUo5Ui94MAoK
kind: Secret
metadata:
    name: htpass-secret
    namespace: openshift-config
type: Opaque
EOF
```

##### Create oauth configuration

```bash
cat > conf/openshift/99_openshift-auth_htpasswd.yaml << EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - htpasswd:
      fileData:
        name: htpass-secret
    mappingMethod: claim
    name: Local
    type: HTPasswd
```

#### Install your cluster

```bash
openshift-install create cluster --dir=conf
```

The caveat here is, you can not adjust objects there created by cluster version operator. Let's take a closer look, using the openshift ingress controller. The initial deploying of the openshift ingress (ex router) component is quite easy: 

The Cluster Version Operator (CVO) ensure the (1) openshift-ingress-operator is running and (2) create the default custom resource (CR) for the default router. 

Ingress part of the CVO is configurated via:

```bash
cat manifests/cluster-ingress-02-config.yml
apiVersion: config.openshift.io/v1
kind: Ingress
metadata:
  creationTimestamp: null
  name: cluster
spec:
  domain: apps.ocp4.aws.bohne.io
status: {}
```

The CR for the default router, created by the CVO:

```bash
$ oc get ingresscontrollers.operator.openshift.io/default -n openshift-ingress-operator -o yaml
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  creationTimestamp: "2019-07-02T16:31:41Z"
  finalizers:
  - ingresscontroller.operator.openshift.io/finalizer-ingresscontroller
  generation: 3
  name: default
  namespace: openshift-ingress-operator
  resourceVersion: "5297947"
  selfLink: /apis/operator.openshift.io/v1/namespaces/openshift-ingress-operator/ingresscontrollers/default
  uid: df423307-9ce6-11e9-a438-525400116dcd
spec:
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2019-07-02T16:32:13Z"
    status: "True"
    type: Available
  domain: apps.ocp4-upi.bohne.io
  endpointPublishingStrategy:
    type: HostNetwork
  selector: ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default
```

The openshift-ingress-operator ensures that running router pods:

```bsah
$ oc get pods -n openshift-ingress
NAME                              READY   STATUS    RESTARTS   AGE
router-default-5769db9885-9s2sl   1/1     Running   1          4d1h
router-default-5769db9885-cvw52   1/1     Running   1          4d1h
```

But it is not supported to pass certificates from CVO to router pods via opemshift-ingress-operator. To solve the problem we need a kind of customer-cluster-operator to adjust the CR of the openshift-ingress-operator. How to write and deploy those operator check-out the next asset.

## 2) Create your own cluster configuration operator - WORK IN PROGRESS

### Create Skeleton

```bash
operator-sdk new cluster-configurator  --type ansible \
  --kind=ClusterConfigurator --generate-playbook \
  --api-version clusterconfig.bohne.io/v1alpha1 \
```

### Do all adjustments
    
Checkout final version: https://github.com/openshift-examples/cluster-configurator

### Build & Push container
  
```
operator-sdk build quay.io/rbo/cluster-configurator:latest
docker push quay.io/rbo/cluster-configurator:latest
```

### Build yaml to deploy via manifests

Pack all together with  [build_installer_yaml.sh](https://github.com/openshift-examples/cluster-configurator/blob/master/build_installer_yaml.sh)

```bash
./build_installer_yaml.sh > 99_openshift-configurator.yaml
```

### Install OpenShift 4 with your Operator

```bash
mkdir conf
cp install-config.yaml conf/
openshift-install create manifests --dir=conf
cp -v 99_openshift-configurator.yaml conf/openshift/
openshift-install create cluster --dir=conf
```


# Resources:

- `--cluster-scoped` is removed, https://github.com/operator-framework/operator-sdk/blob/master/doc/operator-scope.md
- https://github.com/openshift/cluster-ingress-operator
- https://github.com/operator-framework/operator-sdk/issues/1366
- https://github.com/operator-framework/operator-sdk/blob/master/doc/ansible/dev/developer_guide.md#extra-vars-sent-to-ansible