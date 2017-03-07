# EAP Cluster demo


### Grant view permission to default service accont.
This ensures that the EAP can query which PODs are still available.
```
oc policy add-role-to-user view system:serviceaccount:$NAMESPACE$:default -n $NAMESPACE$
```

### Deploy eap with demo application
```
oc process -n openshift eap70-basic-s2i \
   -v SOURCE_REPOSITORY_URL=https://github.com/rbo/openshift-example.git \
      SOURCE_REPOSITORY_REF=master \
      CONTEXT_DIR=eap-cluster/SimpleWebApp | oc create -f -
```

### Scale up deployment to more then 1 pod
```
oc scale --replicas=2 dc/eap-app
```

### Check session replication
```
while true; do \
 curl -s -b JSESSIONID=xxxx \
 http://..../SimpleWebApp/SessionInfoServlet | grep -E '(Hostname|session)' ; done
```

##### Example
```
while true; do  curl -s \
  -b JSESSIONID=BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93.eap-app-1-ngu0d \
  http://eap-app-plain-session-test.paas.osp.consol.de/SimpleWebApp/SessionInfoServlet \
  | grep -E '(Hostname|session)' ; done

  Hostname: eap-app-1-3na1l
  request host: eap-app-plain-session-test.paas.osp.consol.de
  session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
  session createTime:     Tue Mar 07 06:58:17 UTC 2017
  session lastAccessTime: Tue Mar 07 07:22:33 UTC 2017
  Hostname: eap-app-1-ngu0d
  request host: eap-app-plain-session-test.paas.osp.consol.de
  session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
  session createTime:     Tue Mar 07 06:58:17 UTC 2017
  session lastAccessTime: Tue Mar 07 07:26:16 UTC 2017
  Hostname: eap-app-1-3na1l
  request host: eap-app-plain-session-test.paas.osp.consol.de
  session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
  session createTime:     Tue Mar 07 06:58:17 UTC 2017
  session lastAccessTime: Tue Mar 07 07:26:17 UTC 2017
  Hostname: eap-app-1-ngu0d
  request host: eap-app-plain-session-test.paas.osp.consol.de
  session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
  session createTime:     Tue Mar 07 06:58:17 UTC 2017
  session lastAccessTime: Tue Mar 07 07:26:17 UTC 2017
  Hostname: eap-app-1-3na1l
  request host: eap-app-plain-session-test.paas.osp.consol.de
  session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
  session createTime:     Tue Mar 07 06:58:17 UTC 2017
  session lastAccessTime: Tue Mar 07 07:26:17 UTC 2017
```
