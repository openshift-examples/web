# Auto scale down of deployment configs

Quite old, not tested yet and old fassion way. Next time write an operator! Maybe you can use [https://github.com/zalando-incubator/kopf/blob/master/README.md](https://github.com/zalando-incubator/kopf/blob/master/README.md)

## Build container

scale_down.py:
```python
#!/usr/bin/env python

import openshift
# https://github.com/openshift/openshift-restclient-python/blob/master/openshift/docs/OapiApi.md
from openshift import client, config
from pprint import pprint
from kubernetes.client.rest import ApiException
from datetime import datetime, timedelta
from dateutil.parser import parse
import dateutil.tz


#config.load_kube_config()
config.load_incluster_config()

oapi = client.OapiApi()

# for i in dir(oapi):
    # print i

project_list = oapi.list_project()
for project in project_list.items:
    requester="unknown"
    if 'openshift.io/requester' in project.metadata.annotations.keys():
        requester=project.metadata.annotations['openshift.io/requester']
    if 'bohne.io/auto-scale-down' in project.metadata.annotations.keys():
        d = datetime.now(dateutil.tz.tzutc()) - timedelta(days=int(project.metadata.annotations['bohne.io/auto-scale-down']))
        #print('Name: {}, Create: {}'.format(project.metadata.name, project.metadata.creation_timestamp))

        if project.metadata.creation_timestamp < d :
            try:
                api_response = oapi.list_namespaced_deployment_config(project.metadata.name)
                for dc in api_response.items:
                    if int(dc.status.replicas) > 0 :
                        print("Scale down: dc/{} from {} to 0 (namespace: {}, requester: {} )".format(dc.metadata.name,dc.status.replicas,project.metadata.name,requester))
                        try:
                            oapi.patch_namespaced_deployment_config(dc.metadata.name, project.metadata.name,openshift.client.V1DeploymentConfig(spec=openshift.client.V1DeploymentConfigSpec(replicas=0)))
                        except ApiException as e:
                            print("Exception when calling OapiApi->patch_namespaced_deployment_config_scale: %s\n" % e)
            except ApiException as e:
                print("Exception when calling OapiApi->list_deployment_config_for_all_namespaces: %s\n" % e)
```

Containerfile:
```
FROM python:2

RUN pip install openshift
ADD scale_down.py /scale_down.py

ENV K8S_AUTH_KEY_FILE=/var/run/secrets/kubernetes.io/serviceaccount
ENTRYPOINT ["/scale_down.py"]
CMD []
```

## Setup ScheduledJob

```bash
oc create sa cluster-admin -n openshift-jobs

oc adm policy add-cluster-role-to-user cluster-admin system:serviceaccount:openshift-jobs:cluster-admin
```

```yaml
apiVersion: batch/v2alpha1
kind: ScheduledJob
metadata:
  name: auto-scale-down
spec:
  schedule: 10 22 * * 5
  successfulJobsHistoryLimit: 10
  failedJobsHistoryLimit: 10
  jobTemplate:             
    spec:
      template:
        spec:
          serviceAccount: cluster-admin
          serviceAccountName: cluster-admin
          containers:
          - name: auto-scale-down
            image: auto-scale-down	
          restartPolicy: Never
```
