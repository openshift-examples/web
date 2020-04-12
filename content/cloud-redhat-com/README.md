# cloud.redhat.com

Usefull CLI to manage cloud.redhat.com openshift clusters: [https://github.com/openshift-online/uhc-cli](https://github.com/openshift-online/uhc-cli)

* API behind description [https://api.openshift.com/](https://api.openshift.com/)
* Get a API token: [https://cloud.redhat.com/openshift/token](https://cloud.redhat.com/openshift/token)

## Get a API token

[https://cloud.redhat.com/openshift/token](https://cloud.redhat.com/openshift/token)

## How to work with curl

Store bearer token in `$TOKEN`:

```bash
OFFLINE_ACCESS_TOKEN="\
[..snipped..]
"
export TOKEN=$(curl \
--silent \
--data-urlencode "grant_type=refresh_token" \
--data-urlencode "client_id=cloud-services" \
--data-urlencode "refresh_token=${OFFLINE_ACCESS_TOKEN}" \
https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token | \
jq -r .access_token)
```

### List clusters

```bash
curl -X GET "https://api.openshift.com/api/clusters_mgmt/v1/clusters" -H "accept: application/json"  -H "Authorization: Bearer $TOKEN"
```

CSV:

```bash
curl -s -X GET \
  "https://api.openshift.com/api/clusters_mgmt/v1/clusters" \
  -H "accept: application/json"  \
  -H "Authorization: Bearer $TOKEN"  \
  | jq -r ' .items[] | [.creation_timestamp,.name,.id,.state] |@csv'
```

### Delete a cluster

```bash
curl -X DELETE "https://api.openshift.com/api/clusters_mgmt/v1/clusters/$CLUSTER-ID$?deprovision=false" -H "accept: application/json" -H "Authorization: Bearer $TOKEN"
```

### Delete all clusters:

```bash
curl -s -X GET "https://api.openshift.com/api/clusters_mgmt/v1/clusters" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    | jq -r ' .items[] | .id' \
    | xargs -n1 -I{} curl -X DELETE "https://api.openshift.com/api/clusters_mgmt/v1/clusters/{}?deprovision=false" \
    -H "accept: application/json" \
    -H "Authorization: Bearer $TOKEN"
```

### Delete several clusters:

```bash
curl -s -X GET "https://api.openshift.com/api/clusters_mgmt/v1/clusters" -H "accept: application/json"  -H "Authorization: Bearer $TOKEN"  | jq -r ' .items[] | [.creation_timestamp,.id]|@csv' | grep '"2019-07-'| tr -d '"' | while read line ; do curl -v -X DELETE "https://api.openshift.com/api/clusters_mgmt/v1/clusters/${line#*,}?deprovision=false" -H "accept: application/json" -H "Authorization: Bearer $TOKEN" ; done
```

