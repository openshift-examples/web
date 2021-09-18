#!/usr/bin/env bash

########################
# include the magic
########################
. demo-magic.sh


########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=30

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${RED}  ${CYAN}\W "

# text color
# DEMO_CMD_COLOR=$BLACK

# hide the evidence
clear

pei "podman login quay.io"

# pei "oc login "

pei "mkdir sample-operator"
pei "cd sample-operator"

pei "operator-sdk init \\
  --plugins=ansible.sdk.operatorframework.io/v1 \\
  --domain=example.com \\
  --group=app --version=v1alpha1 --kind=AppService \\
  --generate-playbook \\
  --generate-role"


pei "# Add your playbooks "
pei "cp ../example-tasks.yaml roles/appservice/tasks/main.yml"

pei "make docker-build docker-push \\
  IMG=\"quay.io/openshift-examples/ansible-example-operator:latest\" "

pei "make deploy \\
  IMG=\"quay.io/openshift-examples/ansible-example-operator:latest\" "


pei "kubectl get pods -n sample-operator-system --watch"

pei "cat config/samples/app_v1alpha1_appservice.yaml"

pei "kubectl apply -f config/samples/app_v1alpha1_appservice.yaml"

pei "kubectl logs -n sample-operator-system \\
    -l control-plane=controller-manager -c manager --tail=-1"

#make bundle IMG="quay.io/openshift-examples/ansible-example-operator:latest"

#make bundle-build bundle-push \
#  BUNDLE_IMG="quay.io/openshift-examples/ansible-example-operator:bundle"

