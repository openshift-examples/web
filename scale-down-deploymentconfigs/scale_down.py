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
