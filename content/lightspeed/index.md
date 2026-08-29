---
title: Lightspeed
linktitle: Lightspeed
description: All about OpenShift Lightspeed
tags: ['ai','lightspeed','v4.20']
icon: redhat/Technology_icon-Red_Hat-Ansible_Lightspeed-Standard-RGB
---
# All about OpenShift Lightspeed

Resources:
 * <https://developers.redhat.com/articles/2025/11/05/use-openshift-lightspeed-locally-served-llms>

```yaml
apiVersion: ols.openshift.io/v1alpha1
kind: OLSConfig
metadata:
  name: cluster
spec:
  llm:
    providers:
      - credentialsSecretRef:
          name: azure-api-keys
        deploymentName: gpt-4
        models:
          - name: gpt-4
        name: Azure
        type: azure_openai
        url: 'https://llm-gpt4-lightspeed.cognitiveservices.azure.com/'
  ols:
    defaultModel: gpt-4
    defaultProvider: Azure
    introspectionEnabled: true
    logLevel: DEBUG
    queryFilters:
      - name: ip-address
        pattern: '((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}'
        replaceWith: <IP-ADDRESS>
    rag:
      - image: 'quay.io/dialvare/acme-byok:latest'
        indexID: ''
        indexPath: /rag/vector_db
```



```yaml
apiVersion: ols.openshift.io/v1alpha1
kind: OLSConfig
metadata:
  labels:
    app.kubernetes.io/created-by: lightspeed-operator
    app.kubernetes.io/instance: olsconfig-sample
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: olsconfig
    app.kubernetes.io/part-of: lightspeed-operator
  name: cluster
spec:
  llm:
    providers:
      - credentialsSecretRef:
          name: credentials
        models:
          - name: granite-8b-code
            url: 'https://granite-8b-code-code-assistant.apps.cluster-v7lnz.v7lnz.sandbox5321.opentlc.com/v1'
        name: granite-8b-code
        type: rhoai_vllm
        url: 'https://granite-8b-code-code-assistant.apps.cluster-v7lnz.v7lnz.sandbox5321.opentlc.com/v1'
  ols:
    conversationCache:
      postgres:
        credentialsSecret: lightspeed-postgres-secret
        dbName: postgres
        maxConnections: 2000
        sharedBuffers: 256MB
        user: postgres
      type: postgres
    defaultModel: granite-8b-code
    defaultProvider: granite-8b-code
    deployment:
      console:
        replicas: 1
      replicas: 1
    introspectionEnabled: true
    logLevel: DEBUG
  olsDataCollector:
    logLevel: INFO
```


Official documentation:

Tested with:

|Component|Version|
|---|---|
|OpenShift|v4.17.14|
|OpenShift Virt|v4.17.4|


- Cross-cluster VM live migration (TP)
- Light Speed
    - anyuid
    - Ingress encrypte anntionation
    - Deployment - RWO & Node anti afitnity ✅
    - Pod Logs permissions denied 
