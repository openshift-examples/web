# Usefull commands


## List all Services from ansible-service-broker
```
 curl -k -s $(oc get broker ansible-service-broker -o go-template='{{.spec.url}}v2/catalog') | jq ' .services[] | {Name: .name, displayName: .metadata.displayName}'
{
  "Name": "dh--latest",
  "displayName": "Hello World (APB)"
}
```

## List all services from template broker:
```
curl -s -k -X GET -H "Authorization: Bearer $(oc whoami -t)" -H "X-Broker-Api-Version: 2.7"  https://192.168.37.1:8443/brokers/template.openshift.io/v2/catalog | jq ' .services[] | {Name: .name, displayName: .metadata.displayName}'
```


## List all services from service catalog
```
curl -s -k -X GET -H "Authorization: Bearer $(oc whoami -t)" https://192.168.37.1:8443/apis/servicecatalog.k8s.io/v1alpha1/serviceclasses | jq ' .items[] | { brokerName: .brokerName, name: .metadata.name, displayName: .externalMetadata.displayName } '
```