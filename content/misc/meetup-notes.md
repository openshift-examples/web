---
title: ConSol Meetup Notes
linktitle: ConSol Meetup Notes
weight: 99300
description: TBD
---
# My OpenShift 4 Meetup @ConSol Notes


- Red Hat intern
    - [https://docs.google.com/presentation/d/1us-bvx92JCO9eyF2QirPOkdwSjH0KCCAW0vTP9wHnlg](https://docs.google.com/presentation/d/1us-bvx92JCO9eyF2QirPOkdwSjH0KCCAW0vTP9wHnlg)
    - [Kubernetes Operators and OpenShift - Red Hat intern](https://docs.google.com/presentation/d/1edNmcy1jRLk6EAKH6lHhn6msqE0ODqKhOV4x9iKTeGU)
    - [What's new OpenShift 4.1 - Red Hat intern](https://docs.google.com/presentation/d/1as3eDtRPPTQigwhOptbnZoc4yL2mN21Nj18cd0wJocI)

### Installation an OCP4 on AWS

#### Basic installation

```
$ cd ~/q/my-hetzner-lab/
$ openshift-install create cluster --dir=aws-cluster
? SSH Public Key /Users/rbohne/.ssh/15inch.rsa.pub
? Platform aws
? Region eu-central-1
? Base Domain aws.bohne.io
? Cluster Name ocp4
? Pull Secret [? for help]....
```

#### Setup real certificates

```
oc create secret tls router-certs --cert=certificates/ocp4.aws.bohne.io/fullchain.crt --key=certificates/ocp4.aws.bohne.io/cert.key -n openshift-ingress
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" }}}'

```


#### Setup authetification

```
oc create secret generic google-secret --from-literal=clientSecret=pIJrbzRVeNE6QzDzArmXEMut -n openshift-config
htpasswd -n admin >> htpasswd
htpasswd -n user1 >> htpasswd
oc create secret generic htpass-secret --from-file=htpasswd=htpasswd -n openshift-config
oc apply -f - <<EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: Local
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
  - name: RedHatSSO
    mappingMethod: claim
    type: Google
    google:
      clientID: "1079812798374-40es8d8ugvg3e54csnesgf94p6r4rc6s.apps.googleusercontent.com"
      clientSecret:
        name: google-secret
      hostedDomain: "redhat.com"
EOF
# Taks a while
oc adm policy add-cluster-role-to-user cluster-admin admin
# Remove kube-admin
oc delete secret kubeadmin -n kube-system
```


#### Update Cluster

```
oc adm upgrade --to-latest

watch 'oc get clusterversion;echo;echo; oc get clusteroperators'

```


Usefull commands: https://www.underkube.com/posts/ocp4_tips_and_tricks/


## Operator

### How to consume an operator
```
apiVersion: etcd.database.coreos.com/v1beta2
kind: EtcdCluster
metadata:
  name: example
  annotations:
    etcd.database.coreos.com/scope: clusterwide
  namespace: rbohne-etcd-test
spec:
  size: 3
  version: 3.2.13
```


### How to create an operatore & publish in cluster

https://github.com/operator-framework/getting-started


#### Create operator skeleton
#### Add helm charts
#### Try it
#### Upload to your Application repo
#### Add your application repo to OpenShift 4

#### Push to quay

https://github.com/operator-framework/community-operators/blob/master/docs/testing-operators.md


#### Add quay resources to cluster

```
apiVersion: operators.coreos.com/v1
kind: OperatorSource
metadata:
  name: johndoe-operators
  namespace: marketplace
spec:
  type: appregistry
  endpoint: https://quay.io/cnr
  registryNamespace: johndoe
```

### Bash History

```
20646  2019-06-13 14:43:37 curl -OJL https://github.com/operator-framework/operator-sdk/releases/download/v0.8.1/operator-sdk-v0.8.1-x86_64-apple-darwin
20647  2019-06-13 14:44:03 mv operator-sdk-v0.8.1-x86_64-apple-darwin /usr/local/bin/operator-sdk
20648  2019-06-13 14:44:09 chmod +x /usr/local/bin/operator-sdk
20649  2019-06-13 14:44:12 operator-sdk new chaos-professor-operator   --api-version=bohne.io/v1alpha1   --kind=chaos-professor   --type=helm
20650  2019-06-13 14:44:28 operator-sdk new --help
20651  2019-06-13 14:45:44 operator-sdk --version
20652  2019-06-13 14:45:49 type operator-sdk
20653  2019-06-13 14:45:55 rm -rf /Volumes/Development/Go/bin/operator-sdk
20654  2019-06-13 14:45:57 operator-sdk --version
20681  2019-06-16 14:01:21 operator-sdk olm-catalog gen-csv --csv-version 0.0.1





    etcdctl --version
etcdctl version: 3.1.0
API version: 2

etcdctl mkdir /version-info
etcdctl set /version-info/current 3.1.0
etcdctl get /version-info/current


oc create secret generic aws --from-file=/Users/rbohne/.aws/credentials --from-file=/Users/rbohne/.aws/config
aws s3api create-bucket --bucket rbohne-etcd-backup --region eu-central-1 --create-bucket-configuration LocationConstraint=eu-central-1
http://rbohne-etcd-backup.s3.amazonaws.com/


apiVersion: etcd.database.coreos.com/v1beta2
kind: EtcdBackup
metadata:
  name: example-etcd-cluster-backup
  namespace: rbohne-etcd-test
spec:
  etcdEndpoints:
    - http://my-cool-etcd-cluster-client:2379
  storageType: S3
  s3:
    path: http://rbohne-etcd-backup.s3.amazonaws.com/etcd-backup
    awsSecret: aws




20208  2019-06-12 15:23:16 curl -s https://quay.io/cnr/api/v1/packages/
20209  2019-06-12 15:23:41 curl -s https://quay.io/cnr/api/v1/packages/ | jq
20210  2019-06-12 15:24:41 curl -s https://quay.io/cnr/api/v1/packages/community-operators
20211  2019-06-12 15:25:00 curl -s https://quay.io/cnr/api/v1/packages/community-operators/appregistry
20212  2019-06-12 15:25:04 curl -s https://quay.io/cnr/api/v1/packages/community-operators/appregistry/
20213  2019-06-12 15:26:43 curl -s https://quay.io/cnr/api/v1/packages/community-operators/community-operators/openshift-pipelines-operator
20214  2019-06-12 15:26:55 curl -s https://quay.io/cnr/api/v1/packages/community-operators/community-operators/openshift-pipelines-operator/0.3.2
20215  2019-06-12 15:27:02 curl -s https://quay.io/cnr/api/v1/packages/community-operators/community-operators/openshift-pipelines-operator/0.3.2/help/pull
20216  2019-06-12 15:27:13 curl -s https://quay.io/cnr/api/v1/packages/community-operators/openshift-pipelines-operator/0.3.2/help/pull
20217  2019-06-12 15:27:24 curl -s https://quay.io/cnr/api/v1/packages/community-operators/openshift-pipelines-operator/0.3.2
20218  2019-06-12 15:27:32 curl -s https://quay.io/cnr/api/v1/packages/community-operators/openshift-pipelines-operator/0.3.2 | jq
20219  2019-06-12 15:27:51 curl -s https://quay.io/cnr/api/v1/packages/community-operators/openshift-pipelines-operator/0.3.2/helm/pull
20220  2019-06-12 15:28:07 curl -s https://quay.io/cnr/api/v1/packages/community-operators/openshift-pipelines-operator/0.3.2/helm/pull | jq -r .blob
20221  2019-06-12 15:28:18 curl -s https://quay.io/cnr/api/v1/packages/community-operators/openshift-pipelines-operator/0.3.2/helm/pull > f.tgz

```

- [https://docs.google.com/document/d/1UUuXn2iCjEJmJ0MTdizrHuFcWANt4ag-7ZlbMONAF2M/edit#](https://docs.google.com/document/d/1UUuXn2iCjEJmJ0MTdizrHuFcWANt4ag-7ZlbMONAF2M/edit#)
- [https://github.com/operator-framework/operator-registry/tree/c47dd67b03ed95cc4d6566a16665291b7645787b/manifests/prometheus/0.22.2](https://github.com/operator-framework/operator-registry/tree/c47dd67b03ed95cc4d6566a16665291b7645787b/manifests/prometheus/0.22.2)
- [https://github.com/operator-framework/operator-marketplace/commit/c4b239ed2a5948a3545fa7489e272f34f42c0f19](https://github.com/operator-framework/operator-marketplace/commit/c4b239ed2a5948a3545fa7489e272f34f42c0f19)
-  Ansible: [https://github.com/operator-framework/operator-sdk/blob/master/doc/ansible/dev/advanced_options.md](https://github.com/operator-framework/operator-sdk/blob/master/doc/ansible/dev/advanced_options.md)


## Ansible Operator
```
$ operator-sdk new ansible-example-operator   --api-version=bohne.io/v1   --kind=AnsibleExampleOperator   --type=ansible

$ operator-sdk build quay.io/openshift-examples/ansible-example-operator:v0.0.1


$ sed -i "" 's|REPLACE_IMAGE|quay.io/openshift-examples/ansible-example-operator:v0.0.1|g' deploy/operator.yaml
$ docker push quay.io/openshift-examples/ansible-example-operator:v0.0.1


oc4 create -f deploy/crds/bohne_v1_ansibleexampleoperator_crd.yaml
oc4 create -f deploy/role.yaml
oc4 create -f deploy/role_binding.yaml
oc4 create -f deploy/service_account.yaml
oc4 create -f deploy/operator.yaml

```
