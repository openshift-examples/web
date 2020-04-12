# Grafana with OAuth Proxy
## Build
```yaml
---
apiVersion: v1
kind: ImageStream
metadata:
  labels:
    app: grafana
  name: grafana
---
apiVersion: v1
kind: BuildConfig
metadata:
  labels:
    app: grafana
  name: grafana
spec:
  failedBuildsHistoryLimit: 5
  nodeSelector: null
  output:
    to:
      kind: ImageStreamTag
      name: grafana:latest
  postCommit: {}
  resources: {}
  runPolicy: Serial
  source:
    git:
      ref: master
      uri: https://github.com/rbo/grafana-docker.git
    type: Git
  strategy:
    dockerStrategy: {}
    type: Docker
  successfulBuildsHistoryLimit: 5
  triggers:
  - type: ConfigChange
```
## Deployment
```yaml
kind: List
apiVersion: v1
items:
# Create a proxy service account and ensure it will use the route "proxy"
- apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: grafana
    annotations:
      serviceaccounts.openshift.io/oauth-redirectreference.primary: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"grafana"}}'
# Create a secure connection to the proxy via a route
- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    name: grafana
  spec:
    to:
      name: grafana
    tls:
      termination: Reencrypt
- apiVersion: v1
  kind: Service
  metadata:
    name: grafana
    annotations:
      service.alpha.openshift.io/serving-cert-secret-name: grafana-tls
  spec:
    ports:
    - name: grafana
      port: 443
      targetPort: 8443
    selector:
      app: grafana
- apiVersion: v1
  kind: DeploymentConfig
  metadata:
    labels:
      app: grafana
    name: grafana
  spec:
    replicas: 1
    revisionHistoryLimit: 10
    selector:
      deploymentConfig: grafana
    strategy:
      activeDeadlineSeconds: 21600
      recreateParams:
        timeoutSeconds: 600
      resources: {}
      type: Recreate
    template:
      metadata:
        labels:
          app: grafana
          deploymentConfig: grafana
        name: grafana
      spec:
        serviceAccountName: grafana
        containers:
        - name: oauth-proxy
          image: openshift/oauth-proxy:v1.0.0
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 8443
            name: public
          args:
          - --https-address=:8443
          - --provider=openshift
          - --openshift-service-account=grafana
          - --upstream=http://localhost:3000
          - --tls-cert=/etc/tls/private/tls.crt
          - --tls-key=/etc/tls/private/tls.key
          - --cookie-secret=SECRET
          - --pass-basic-auth=false
          volumeMounts:
          - mountPath: /etc/tls/private
            name: grafana-tls
        - image: grafana:latest
          imagePullPolicy: Always
          name: grafana
          env:
          - name: GF_AUTH_BASIC_ENABLED
            value: 'true'
          - name: GF_AUTH_PROXY_ENABLED
            value: 'true'
          - name: GF_AUTH_PROXY_HEADER_NAME
            value: 'X-Forwarded-User'
          - name: GF_AUTH_PROXY_HEADER_PROPERTY
            value: 'username'
          - name: GF_AUTH_PROXY_AUTO_SIGN_UP
            value: 'true'
          - name: GF_AUTH_DISABLE_LOGIN_FORM
            value: 'true'
          - name: GF_USERS_ALLOW_SIGN_UP
            value: 'false'

          ports:
          - containerPort: 3000
            name: http
            protocol: TCP
          resources: {}
          securityContext: {}
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
        volumes:
          - name: grafana-tls
            secret:
              secretName: grafana-tls
        dnsPolicy: ClusterFirst
        restartPolicy: Always
        schedulerName: default-scheduler
        securityContext: {}
        terminationGracePeriodSeconds: 60
    test: false
    triggers:
    - imageChangeParams:
        automatic: true
        containerNames:
        - grafana
        from:
          kind: ImageStreamTag
          name: grafana:latest
      type: ImageChange
    - type: ConfigChange

```