---
title: Restore
linktitle: Restore
description: Some information about restore
tags:
  - restore
  - kubeconfig
---

# Some information about restore

## Restore kubeconfig

```bash
cat .openshift_install_state.json \
    | jq '.["*kubeconfig.AdminClient"].File.Data' -r \
    | base64 -d > kubeconfig
```

## Restore kube-scheduler

Or follow the KCS: [Kube-scheduler is not scheduling pods due to client certificate not renewed automatically in OpenShift 4](https://access.redhat.com/solutions/5442201)

If pods stucks in Pending, might a problem with kube scheduler.

Problem expired cert:
```bash hl_lines="6 7"
$ kubectl describe secret kube-scheduler-client-cert-key -n openshift-kube-scheduler
Name:         kube-scheduler-client-cert-key
Namespace:    openshift-kube-scheduler
Labels:       auth.openshift.io/managed-certificate-type=target
Annotations:  auth.openshift.io/certificate-issuer: kube-control-plane-signer
              auth.openshift.io/certificate-not-after: 2021-01-30T19:47:44Z
              auth.openshift.io/certificate-not-before: 2020-12-31T19:47:43Z

Type:  kubernetes.io/tls

Data
====
tls.key:  1675 bytes
tls.crt:  1168 bytes

$ ssh -l core <master-0>
[core@master-0 ~]$ sudo su - 
Last login: Tue Feb  2 14:20:52 UTC 2021 on pts/0
[root@master-0 ~]# openssl x509 -noout -dates -in /etc/kubernetes/static-pod-resources/kube-scheduler-certs/secrets/kube-scheduler-client-cert-key/tls.crt 
notBefore=Dec 31 19:47:43 2020 GMT
notAfter=Jan 30 19:47:44 2021 GMT
```




### Check client cert sync on master nodes
```bash
[root@master-0 ~]# crictl logs --tail 10 $(crictl ps --name kube-scheduler-cert-syncer -q) 
I0202 14:28:08.544428       1 certsync_controller.go:65] Syncing configmaps: []
I0202 14:28:08.544441       1 certsync_controller.go:162] Syncing secrets: [{kube-scheduler-client-cert-key false}]
I0202 14:38:08.500345       1 certsync_controller.go:65] Syncing configmaps: []
I0202 14:38:08.500375       1 certsync_controller.go:162] Syncing secrets: [{kube-scheduler-client-cert-key false}]
I0202 14:38:08.502818       1 certsync_controller.go:65] Syncing configmaps: []
I0202 14:38:08.502845       1 certsync_controller.go:162] Syncing secrets: [{kube-scheduler-client-cert-key false}]
I0202 14:38:08.544282       1 certsync_controller.go:65] Syncing configmaps: []
I0202 14:38:08.544328       1 certsync_controller.go:162] Syncing secrets: [{kube-scheduler-client-cert-key false}]
I0202 14:38:08.544698       1 certsync_controller.go:65] Syncing configmaps: []
I0202 14:38:08.544716       1 certsync_controller.go:162] Syncing secrets: [{kube-scheduler-client-cert-key false}]
[root@master-0 ~]# date
Tue Feb  2 14:41:11 UTC 2021
[root@master-0 ~]# 
```

=> Sync every 10 minutes


### Manuel renewal 


```bash
mkdir kube-control-plane-signer 
cd $_
kubectl get secrets -n openshift-kube-apiserver-operator \
  kube-control-plane-signer \
  -o jsonpath="{.data.tls\.crt}" \
  | base64 -d > kube-control-plane-signer.crt

kubectl get secrets -n openshift-kube-apiserver-operator \
  kube-control-plane-signer \
  -o jsonpath="{.data.tls\.key}" \
  | base64 -d > kube-control-plane-signer.key

kubectl get secret -n openshift-kube-scheduler \
  kube-scheduler-client-cert-key \
  -o jsonpath="{.data.tls\.key}" \
  | base64 -d > openshift-kube-scheduler.key

# Create new certificate request
openssl req -new \
  -key openshift-kube-scheduler.key \
  -out openshift-kube-scheduler.csr \
  -subj "/CN=system:kube-scheduler"

# Sign certificate request - only one day to enforce renewal by OpenShift
openssl x509 -req \
  -in openshift-kube-scheduler.csr \
  -CA kube-control-plane-signer.crt \
  -CAkey kube-control-plane-signer.key \
  -CAcreateserial \
  -out openshift-kube-scheduler.crt \
  -days 1

# Update secret
kubectl create secret tls kube-scheduler-client-cert-key  \
  --namespace openshift-kube-scheduler \
  --save-config --dry-run=client \
  --key=openshift-kube-scheduler.key \
  --cert=openshift-kube-scheduler.crt \
  -o yaml | kubectl apply -f -
```

**Check `kube-scheduler-cert-syncer` and `kube-scheduler`:** 

```
[root@master-0 ~]# crictl logs --tail 1 $(crictl ps --name kube-scheduler-cert-syncer -q) 
I0202 14:56:04.698961       1 event.go:282] Event(v1.ObjectReference{Kind:"Pod", Namespace:"openshift-kube-scheduler", Name:"openshift-kube-scheduler-master-0", UID:"", APIVersion:"v1", ResourceVersion:"", FieldPath:""}): type: 'Normal' reason: 'CertificateUpdated' Wrote updated secret: openshift-kube-scheduler/kube-scheduler-client-cert-key
[root@master-0 ~]# 

[root@master-0 ~]# crictl logs --tail 1 $(crictl ps --name kube-scheduler -q) 
I0202 14:56:04.698961       1 event.go:282] Event(v1.ObjectReference{Kind:"Pod", Namespace:"openshift-kube-scheduler", Name:"openshift-kube-scheduler-master-0", UID:"", APIVersion:"v1", ResourceVersion:"", FieldPath:""}): type: 'Normal' reason: 'CertificateUpdated' Wrote updated secret: openshift-kube-scheduler/kube-scheduler-client-cert-key
[root@master-0 ~]# 
```
