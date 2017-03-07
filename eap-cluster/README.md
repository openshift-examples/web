# EAP Cluster demo

```
oc policy add-role-to-user view system:serviceaccount:$NAMESPACE$:default -n $NAMESPACE$
oc process -n openshift eap70-basic-s2i -v SOURCE_REPOSITORY_URL=https://github.com/rbo/openshift-example.git SOURCE_REPOSITORY_REF=master CONTEXT_DIR=eap-cluster/SimpleWebApp | oc create -f -
```

```
while true; do  curl -b JSESSIONID=BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93.eap-app-1-ngu0d http://eap-app-plain-session-test.paas.osp.consol.de/SimpleWebApp/SessionInfoServlet  ; done

<pre>
Hostname: eap-app-1-3na1l
Served at: /SimpleWebApp

request host: eap-app-plain-session-test.paas.osp.consol.de
request port: 80

application server: WildFly 2.1.10.Final-redhat-1 - 1.3.25.Final-redhat-1

session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
session createTime:     Tue Mar 07 06:58:17 UTC 2017
session lastAccessTime: Tue Mar 07 07:05:19 UTC 2017

=== cookies ===
name: JSESSIONID, value: BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93.eap-app-1-ngu0d, comment: null, MaxAge: -1, Path: null

=== attributes ===
attribute name:  attr1
attribute type:  String
attribute value: sdf


</pre>
<a href="/SimpleWebApp/form.html" target="_blank">set attribute</a>
<pre>
Hostname: eap-app-1-ngu0d
Served at: /SimpleWebApp

request host: eap-app-plain-session-test.paas.osp.consol.de
request port: 80

application server: WildFly 2.1.10.Final-redhat-1 - 1.3.25.Final-redhat-1

session id:             BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93
session createTime:     Tue Mar 07 06:58:17 UTC 2017
session lastAccessTime: Tue Mar 07 07:05:19 UTC 2017

=== cookies ===
name: JSESSIONID, value: BADC1YHolI-iE2e2ffGyfU8cODN2pDQ8mnPZDM93.eap-app-1-ngu0d, comment: null, MaxAge: -1, Path: null

=== attributes ===
attribute name:  attr1
attribute type:  String
attribute value: sdf


</pre>
<a href="/SimpleWebApp/form.html" target="_blank">set attribute</a>
```
