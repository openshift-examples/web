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

## Templates

 * <https://github.com/openshift-examples/client-go-template>
 * <https://www.openshift.com/blog/customizing-oc-output-with-go-templates>
 * <https://github.com/brandisher/openshift-and-gotemplates-workshop>
 
### List of Pods with resources

```
cat > podlist-with-resources.gotemplate <<'EOF'
--8<-- "content/client/client-go-template/podlist-with-resources.gotemplate"
EOF


oc get pods -n openshift-monitoring -o go-template-file=podlist-with-resources.gotemplate
NAMESPACE                                         	POD NAME                                          	CONTAINER NAME                                    	RESOURCES
openshift-monitoring                              	alertmanager-main-0                               	alertmanager                                      	map[requests:map[cpu:4m memory:200Mi]]
openshift-monitoring                              	alertmanager-main-0                               	config-reloader                                   	map[requests:map[cpu:1m memory:10Mi]]
openshift-monitoring                              	alertmanager-main-0                               	alertmanager-proxy                                	map[requests:map[cpu:1m memory:20Mi]]
openshift-monitoring                              	alertmanager-main-0                               	kube-rbac-proxy                                   	map[requests:map[cpu:1m memory:20Mi]]
openshift-monitoring                              	alertmanager-main-0                               	prom-label-proxy                                  	map[requests:map[cpu:1m memory:20Mi]]
openshift-monitoring                              	alertmanager-main-1                               	alertmanager                                      	map[requests:map[cpu:4m memory:200Mi]]

... 
```

