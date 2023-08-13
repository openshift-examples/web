---
title: OpenShift/Kubernetes Client
linktitle: Client (oc/kubectl)
description: All about OpenShift/Kubernetes clients
tags:
  - client
  - kubectl
  - oc
---

#  OpenShift/Kubernetes Client

## Resources

 * <https://github.com/openshift-examples/client-go-template>
 * <https://www.openshift.com/blog/customizing-oc-output-with-go-templates>
 * <https://github.com/brandisher/openshift-and-gotemplates-workshop>


## Different Pod details

### List of Pods with resources

=== "CLI"

    ```
    curl -O -L {{ page.canonical_url }}podlist-with-resources.gotemplate
    oc get pods -n openshift-monitoring -o go-template-file=podlist-with-resources.gotemplate
    ```

=== "Go Template"

    ```go
    --8<-- "content/client/podlist-with-resources.gotemplate"
    ```

=== "Example Output"

    ```bash
    --8<-- "content/client/podlist-with-resources.example"

    ```

## cURL & Kubernetes/OpenShift API examples

```text
$ curl --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
  --header "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" \
  https://kubernetes.default.svc.cluster.local/version

{
  "major": "1",
  "minor": "16+",
  "gitVersion": "v1.16.2",
  "gitCommit": "4320e48",
  "gitTreeState": "clean",
  "buildDate": "2020-01-21T19:50:59Z",
  "goVersion": "go1.12.12",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```