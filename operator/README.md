# Operator

## Ansible Operator example

#### Resources:

* [OperatorSDK](https://github.com/operator-framework/operator-sdk/) \( [Example](https://github.com/operator-framework/operator-sdk/#create-and-deploy-an-app-operator) \)

#### Create first ansible operator

{% tabs %}
{% tab title="" %}
```bash
operator-sdk new ansible-operator \
    --api-version=ansible-operator.openshift.pub/v1  \
    --kind=Config \
    --type=ansible
cd ansible-operator

operator-sdk build quay.io/openshift-examples/ansible-example-operator:latest
docker push quay.io/openshift-examples/ansible-example-operator:latest

sed -i "" 's|{{ REPLACE_IMAGE }}|quay.io/openshift-examples/ansible-example-operator:latest|g' deploy/operator.yaml
sed -i "" 's|{{ pull_policy\|default('\''Always'\'') }}|Always|g' deploy/operator.yaml

oc new-project ansible-example-operator 
# Setup Service Account
oc create -f deploy/service_account.yaml
# Setup RBAC
oc create -f deploy/role.yaml
oc create -f deploy/role_binding.yaml
# Setup the CRD
oc create -f deploy/crds/ansibleoperator_v1_config_crd.yaml
# Deploy the app-operator
oc create -f deploy/operator.yaml

# Create an AppService CR
# The default controller will watch for AppService objects and create a pod for each CR
oc create -f deploy/crds/ansibleoperator_v1_config_cr.yaml
```
{% endtab %}
{% endtabs %}

#### Adjust `roles/config/tasks/main.yml`

```text
---
# tasks file for config
- name: Print some debug information
  vars:
    msg: |
        Module Variables ("vars"):
        --------------------------------
        {{ vars | to_nice_json }}

        Environment Variables ("environment"):
        --------------------------------
        {{ environment | to_nice_json }}

        GROUP NAMES Variables ("group_names"):
        --------------------------------
        {{ group_names | to_nice_json }}

        GROUPS Variables ("groups"):
        --------------------------------
        {{ groups | to_nice_json }}

        HOST Variables ("hostvars"):
        --------------------------------
        {{ hostvars | to_nice_json }}

  debug:
    msg: "{{ msg.split('\n') }}"  
```

#### Rebuild and redeploy

{% tabs %}
{% tab title="" %}
```bash
operator-sdk build quay.io/openshift-examples/ansible-example-operator:latest
docker push quay.io/openshift-examples/ansible-example-operator:latest
oc delete pods -l name=ansible-operator
```
{% endtab %}
{% endtabs %}

#### Cleanup

```bash
# Setup Service Account
oc delete -f deploy/crds/ansibleoperator_v1_config_crd.yaml
oc delete project ansible-example-operator 
```

