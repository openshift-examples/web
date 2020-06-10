
!!! note
    Deprecated in OpenShift 4


## Simple pipeline Demo

```text
oc new-project pipeline
oc new-app jenkins-ephemeral
oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/pipeline/nodejs-sample-pipeline.yaml
```

## Build and push image into many registries

Based on [Promoting container images between registries with skopeo](https://blog.openshift.com/promoting-container-images-between-registries-with-skopeo/)

Two different ways to get Skopoe "into" Jenkins

1\) Custom Jenkins Slave

```text
https://github.com/siamaksade/openshift-cd-demo/blob/ocp-3.11/cicd-template.yaml#L229

Source for the slave image https://github.com/siamaksade/jenkins-slave-skopeo

Based on https://docs.openshift.com/container-platform/3.11/dev_guide/dev_tutorials/openshift_pipeline.html

https://github.com/redhat-cop/containers-quickstarts/tree/master/jenkins-slaves/jenkins-slave-image-mgmt
```

2\) Custom Jenkins Agent, was the differents?

[https://github.com/jenkinsci/kubernetes-plugin](https://github.com/jenkinsci/kubernetes-plugin) [https://github.com/openshift/jenkins-client-plugin](https://github.com/openshift/jenkins-client-plugin)

```text
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

```text
FROM openshift/jenkins-slave-base-centos7
MAINTAINER Tero Ahonen <tero@redhat.com>
USER root
RUN yum -y install skopeo
USER 1001
```

## Build & Deploy namespace one -&gt; deploy namespace 2

```text
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