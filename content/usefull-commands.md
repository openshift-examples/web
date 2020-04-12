# Usefull commands

## Commands inside a POD

### Get IP Addresses without ip or ifconfig?

#### Command 
```bash
cat /proc/net/fib_trie
```

#### Sample outpout
```
$ cat /proc/net/fib_trie
Main:
  +-- 0.0.0.0/0 3 0 4
     +-- 0.0.0.0/4 2 0 2
        |-- 0.0.0.0
           /0 universe UNICAST
        +-- 10.128.0.0/14 2 0 2
           |-- 10.128.0.0
              /14 universe UNICAST
           +-- 10.131.0.0/23 2 0 2
              +-- 10.131.0.0/28 2 0 2
                 |-- 10.131.0.0
                    /32 link BROADCAST
                    /23 link UNICAST
                 |-- 10.131.0.14
                    /32 host LOCAL
              |-- 10.131.1.255
                 /32 link BROADCAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /32 link BROADCAST
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     |-- 172.30.0.0
        /16 universe UNICAST
     |-- 224.0.0.0
        /4 universe UNICAST
Local:
  +-- 0.0.0.0/0 3 0 4
     +-- 0.0.0.0/4 2 0 2
        |-- 0.0.0.0
           /0 universe UNICAST
        +-- 10.128.0.0/14 2 0 2
           |-- 10.128.0.0
              /14 universe UNICAST
           +-- 10.131.0.0/23 2 0 2
              +-- 10.131.0.0/28 2 0 2
                 |-- 10.131.0.0
                    /32 link BROADCAST
                    /23 link UNICAST
                 |-- 10.131.0.14
                    /32 host LOCAL
              |-- 10.131.1.255
                 /32 link BROADCAST
     +-- 127.0.0.0/8 2 0 2
        +-- 127.0.0.0/31 1 0 0
           |-- 127.0.0.0
              /32 link BROADCAST
              /8 host LOCAL
           |-- 127.0.0.1
              /32 host LOCAL
        |-- 127.255.255.255
           /32 link BROADCAST
     |-- 172.30.0.0
        /16 universe UNICAST
     |-- 224.0.0.0
        /4 universe UNICAST
```

#### Command

```text
cat /proc/net/fib_trie | grep "|--"   | egrep -v "0.0.0.0| 127."
```

#### Sample output

```
$ cat /proc/net/fib_trie | grep "|--"   | egrep -v "0.0.0.0| 127."
           |-- 10.128.0.0
                 |-- 10.131.0.0
                 |-- 10.131.0.14
              |-- 10.131.1.255
     |-- 172.30.0.0
     |-- 224.0.0.0
           |-- 10.128.0.0
                 |-- 10.131.0.0
                 |-- 10.131.0.14
              |-- 10.131.1.255
     |-- 172.30.0.0
     |-- 224.0.0.0
```


### cURL & Kubernetes/OpenShift API examples

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


## List all Services from ansible-service-broker

```text
 curl -k -s $(oc get broker ansible-service-broker -o go-template='{{.spec.url}}v2/catalog') | jq ' .services[] | {Name: .name, displayName: .metadata.displayName}'
{
  "Name": "dh--latest",
  "displayName": "Hello World (APB)"
}
```

## List all services from template broker:

```text
curl -s -k -X GET -H "Authorization: Bearer $(oc whoami -t)" -H "X-Broker-Api-Version: 2.7"  https://192.168.37.1:8443/brokers/template.openshift.io/v2/catalog | jq ' .services[] | {Name: .name, displayName: .metadata.displayName}'
```

## List all services from service catalog

```text
curl -s -k -X GET -H "Authorization: Bearer $(oc whoami -t)" https://192.168.37.1:8443/apis/servicecatalog.k8s.io/v1alpha1/serviceclasses | jq ' .items[] | { brokerName: .brokerName, name: .metadata.name, displayName: .externalMetadata.displayName } '
```