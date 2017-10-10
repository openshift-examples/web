# Put auditlog into elasticsearch
A quick-n-diry example to put the openshift audit log into elasticsearch.
## Installation

-  Edit configmap logging-fluentd ```oc edit configmap/logging-fluentd```
  - Adjust ```fluent.conf```, add ```configs.d/user/input-auditlog.conf``` after ```@include configs.d/openshift/input-post-*.conf```
  - Add ```input-auditlog.conf``` - don't forget to adjust the audit log filename, default: /auditlog/auditlog.log [input-auditlog.conf]() 

## Screenhosts
### Whats happen at namespace rbo?
![](screenshots/example1.png)

### Whats happen with request 604e...
![](screenshots/example2.png)


### Info for oc cluster up users
Start oc cluster up with (mac os)

##### Add Local ip adress 
```sudo ifconfig lo0 alias 192.168.37.1```
##### Start OpenShift
```
oc cluster up \
  --host-config-dir=${BASE_PATH}/host-config-dir/ \
  --host-data-dir=${BASE_PATH}/host-data-dir/ \
  --host-pv-dir=${BASE_PATH}/host-pv-dir/ \
  --public-hostname=192.168.37.1 \
  --logging=true
```

##### Add pv for auditlog to fluent
```
oc create -f pvc.yml -n logging
oc volume daemonset/logging-fluentd --add --mount-path=/auditlog --name=auditlog -t pvc --claim-name=auditlog
```
##### Stop cluster
```
oc cluster down
```
#####  Adjust master config, write audit log pv
In my case:

```
grep audit host-config-dir/master/master-config.yaml
auditConfig:
  auditFilePath: "/Users/rbo/Development/oc-cluster/host-pv-dir/pv0044/auditlog.log"
```
##### Start OpenShift again
```
oc cluster up \
 --service-catalog=true \
 --host-config-dir=${BASE_PATH}/host-config-dir/ \
 --host-data-dir=${BASE_PATH}/host-data-dir/ \
 --host-pv-dir=${BASE_PATH}/host-pv-dir/ \
 --public-hostname=192.168.37.1 \
 --use-existing-config \
 --logging=true
```

