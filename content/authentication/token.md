# Service Account authentication via Token

Official solution: [How to get the authentication token for an OpenShift Service account](https://access.redhat.com/solutions/2972601)

```bash
oc create sa external-pipeline-user


oc get serviceaccount/external-pipeline-user -o yaml
apiVersion: v1
imagePullSecrets:
- name: external-pipeline-user-dockercfg-h8lsb
kind: ServiceAccount
metadata:
  creationTimestamp: "2020-05-15T08:12:17Z"
  name: external-pipeline-user
  namespace: token
  resourceVersion: "858942"
  selfLink: /api/v1/namespaces/token/serviceaccounts/external-pipeline-user
  uid: 09e614a8-58b6-4427-abc2-3ac5e0f8c972
secrets:
- name: external-pipeline-user-dockercfg-h8lsb
- name: external-pipeline-user-token-9mkmv


TOKEN=$(oc get secret/external-pipeline-user-token-9mkmv -o jsonpath={.data.token} | base64 -d)


$ oc login --token=$TOKEN
Logged into "https://api.cnv.openshift.pub:6443" as "system:serviceaccount:token:external-pipeline-user" using the token provided.

You don't have any projects. Contact your system administrator to request a project.

# Or via 

oc sa
Manage service accounts in your project

 Service accounts allow system components to access the API.

Aliases:
serviceaccounts, sa

Usage:
  oc serviceaccounts [flags]

Available Commands:
  create-kubeconfig Generate a kubeconfig file for a service account
  get-token         Get a token assigned to a service account.
  new-token         Generate a new token for a service account.


```