# Build examples

## Simple pipeline Demo
```
oc new-project pipeline
oc new-app jenkins-ephemeral
oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml
```

## Builder -> Runner image

```
# Important to build with an older tag

oc import-image openjdk18-openshift:latest --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift --confirm
oc import-image openjdk18-openshift:1.0 --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:1.0 --confirm

oc new-build --name=build-with-1 --image-stream=openjdk18-openshift:1.0 https://github.com/rbo/chaos-professor.git


echo -e "FROM openjdk18-openshift \nCOPY chaos-professor-0.0.1.jar /deployments/" | oc new-build --name=run-with-latest-1 \
    --image-stream=openjdk18-openshift:latest \
    --source-image=build-with-1 \
    --source-image-path=/tmp/src/target/chaos-professor-0.0.1.jar:. \
    --strategy=docker \
    --dockerfile -

oc new-app build-with-1 && oc expose svc/build-with-1
oc new-app run-with-latest-1 && oc expose svc/run-with-latest-1
```

## Add git config 


[OpenShift 3.11 documenation](https://docs.openshift.com/container-platform/3.11/dev_guide/builds/build_inputs.html#source-secrets-gitconfig-file-secured)


Create ```/tmp/gitconfig```

```ini
[http]
    sslVerify = false
# Just for information:
[core]
    sshCommand = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
```

Run commands: ( Create secret & add ```--source-secret=build``` to new-build )
```sh
oc create secret generic build --from-file=.gitconfig=/tmp/gitconfig \
    --from-file=ssh-privatekey=/tmp/github_rsa \
    --type=kubernetes.io/ssh-auth

oc new-build registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift~git@github.com:rbo/chaos-professor.git --source-secret=build --env BUILD_LOGLEVEL=5

# If you like, create app
oc new-app chaos-professor

```


## Build and push image into many registries

Based on [Promoting container images between registries with skopeo](https://blog.openshift.com/promoting-container-images-between-registries-with-skopeo/)


Two different ways to get Skopoe "into" Jenkins

1) Custom Jenkins Slave
    
    https://github.com/siamaksade/openshift-cd-demo/blob/ocp-3.11/cicd-template.yaml#L229
    
    Source for the slave image https://github.com/siamaksade/jenkins-slave-skopeo

    Based on https://docs.openshift.com/container-platform/3.11/dev_guide/dev_tutorials/openshift_pipeline.html

    https://github.com/redhat-cop/containers-quickstarts/tree/master/jenkins-slaves/jenkins-slave-image-mgmt

2) Custom Jenkins Agent, was the differents?






https://github.com/jenkinsci/kubernetes-plugin
https://github.com/openshift/jenkins-client-plugin

```
podTemplate(
  label: "scopeo", 
  cloud: "openshift", 
  inheritFrom: "maven", 
  containers: [
    containerTemplate(
      name: "jnlp", 
      image: "quay.io/your_repo/jenkins-slave-skopeo-centos:master", 
      resourceRequestMemory: "512Mi", 
      resourceLimitMemory: "1Gi"
    )
  ]
)
```
Dockerfile

```
FROM openshift/jenkins-slave-base-centos7
MAINTAINER Tero Ahonen <tero@redhat.com>
USER root
RUN yum -y install skopeo
USER 1001
```


## Build & Deploy namespace one -> deploy namespace 2

```
oc new-project prod

oc new-project dev

oc process -f https://raw.githubusercontent.com/rbo/openshift-tasks/master/app-template.yaml -p SOURCE_URL=https://github.com/rbo/openshift-tasks | oc create -f -

oc policy add-role-to-group edit system:serviceaccounts:default -n prod

TRIGER: OpenShift ONLY

oc tag dev/tasks:latest prod/tasks:latest
oc project prod
oc new-app tasks
oc expose svc/tasks

# Rollback - OPENSHIFT ONLY!
oc rollback dc/tasks
```

