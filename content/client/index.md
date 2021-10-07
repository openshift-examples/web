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
