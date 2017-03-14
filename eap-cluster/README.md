# EAP Cluster demo
This example demonstrates session replication on JBoss EAP in OpenShift.

### Grant view permission to default service account
This ensures that the EAP can query which PODs are still available:
```
oc policy add-role-to-user view system:serviceaccount:$NAMESPACE$:default -n $NAMESPACE$
```

### Deploy JBoss EAP with demo application
```
oc process -n openshift eap70-basic-s2i \
   -v SOURCE_REPOSITORY_URL=https://github.com/rbo/openshift-example.git \
      SOURCE_REPOSITORY_REF=master \
      CONTEXT_DIR=eap-cluster/SimpleWebApp | oc create -f -
```

### Scale up deployment to more than 1 pod
```
oc scale --replicas=2 dc/eap-app
```

### Enforce roundrobin
This should be default, but we will enforce just in case roundrobin to check the session replication. For more information: [routes.html#route-specific-annotations](https://docs.openshift.com/container-platform/3.4/architecture/core_concepts/routes.html#route-specific-annotations
)
```
oc patch \
  -p '{"metadata":{"annotations":{"haproxy.router.openshift.io/balance": "roundrobin"}}}' \
  route/eap-app
```

### Check session replication
2017-03-14: since there is a haproxy stickyness bug in OCP 3.4 (disable_cookies is ignored), we have to delete the HttpOnly line in our temporary cookie cache.
```
$  while true; do \
     curl -s -b /tmp/mycookies.jar -c /tmp/mycookies.jar \
     http://<your-application-route>/SimpleWebApp/SessionInfoServlet | \
     grep -E '(Hostname|session)'; \
     sleep 1; \
     sed -i '/HttpOnly/d' /tmp/mycookies.jar; \
     echo ""; \
     done
```

##### Example
Expected behaviour: session ID and creation time remains the same, hostname changes.
```
$  while true; do \
>    curl -s -b /tmp/mycookies.jar -c /tmp/mycookies.jar \
>    http://eap-app-zisis.paas.osp.consol.de/SimpleWebApp/SessionInfoServlet | \
>    grep -E '(Hostname|session)'; \
>    sleep 1; \
>    sed -i '/HttpOnly/d' /tmp/mycookies.jar; \
>    echo ""; \
>    done
Hostname: eap-app-1-n52jz
session id:             NtXAm9gUvpHvYPmAmprjH0JBAUA3wGgfEHk4Tzvw
session createTime:     Tue Mar 14 13:52:17 UTC 2017
session lastAccessTime: Tue Mar 14 13:54:18 UTC 2017

Hostname: eap-app-1-m1qz6
session id:             NtXAm9gUvpHvYPmAmprjH0JBAUA3wGgfEHk4Tzvw
session createTime:     Tue Mar 14 13:52:17 UTC 2017
session lastAccessTime: Tue Mar 14 13:55:29 UTC 2017

Hostname: eap-app-1-n52jz
session id:             NtXAm9gUvpHvYPmAmprjH0JBAUA3wGgfEHk4Tzvw
session createTime:     Tue Mar 14 13:52:17 UTC 2017
session lastAccessTime: Tue Mar 14 13:55:30 UTC 2017

Hostname: eap-app-1-m1qz6
session id:             NtXAm9gUvpHvYPmAmprjH0JBAUA3wGgfEHk4Tzvw
session createTime:     Tue Mar 14 13:52:17 UTC 2017
session lastAccessTime: Tue Mar 14 13:55:31 UTC 2017

...
```
