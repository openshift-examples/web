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
TYPE_SPEED=40

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
DEMO_PROMPT="${RED}  ${CYAN}\W "

# text color
# DEMO_CMD_COLOR=$BLACK

CONTROLLER_IMG=quay.io/openshift-examples/ansible-example-operator:latest
BUNDLE_IMG=quay.io/openshift-examples/ansible-example-operator-bundle:latest
INDEX_IMG=quay.io/openshift-examples/ansible-example-operator-index:latest

# hide the evidence
clear
pe
pei "podman login quay.io"

pei "oc login -u admin https://api.demo.openshift.pub:6443 \\
    --insecure-skip-tls-verify=false "

pei "mkdir sample-operator"
pei "cd sample-operator"

pei "operator-sdk init \\
  --plugins=ansible.sdk.operatorframework.io/v1 \\
  --domain=example.com \\
  --group=app --version=v1alpha1 --kind=AppService \\
  --generate-playbook \\
  --generate-role"


pei "tree"

pe "# Add your playbooks "
pei "cp ../example-tasks.yaml roles/appservice/tasks/main.yml"

pei "make docker-build docker-push \\
  IMG=\"quay.io/openshift-examples/ansible-example-operator:latest\" "

pei "make deploy \\
  IMG=\"quay.io/openshift-examples/ansible-example-operator:latest\" "


pei "kubectl get pods -n sample-operator-system --watch"

pei "cat config/samples/app_v1alpha1_appservice.yaml"

pei "kubectl apply -f config/samples/app_v1alpha1_appservice.yaml"

pei "kubectl logs -n sample-operator-system \\
    -l control-plane=controller-manager -c manager -f --tail=-1"

pei "# Undeploy?"

pei "kubectl delete -f config/samples/app_v1alpha1_appservice.yaml"
pei "make undeploy"


pe "# Let's use OLM"

pei "# Create bundle image"

pei "make bundle BUNDLE_METADATA_OPTS=\"--channels preview\" \\
  IMG=\"quay.io/openshift-examples/ansible-example-operator:latest\" "

pei "make bundle-build bundle-push \\
  BUNDLE_IMG=\"quay.io/openshift-examples/ansible-example-operator-bundle:latest\" "

#pei "# Easy way: \\
#        operator-sdk run bundle quay.io/openshift-examples/ansible-example-operator-bundle:latest"

#pei "# Let's do 'the hard way'"

pei "# Create operator index "

# https://olm.operatorframework.io/docs/tasks/creating-an-index/

# pei "cd ../"
# pei "mkdir sample-operator-index"
# pei "opm alpha generate dockerfile sample-operator-index"
# pei "opm init sample-operator \\
#     --default-channel=preview \\
#     --description=./opm-init-desc.md \\
#     --icon=/var/home/rbohne/Pictures/ansible-operator.png \\
#     --output yaml >  sample-operator-index/index.yaml"

# pei "opm render $BUNDLE_IMG \\
#     --output=yaml >> sample-operator-index/index.yaml"

# pei "cat sample-operator-index/index.yaml"


# pei "cat << EOF >> sample-operator-index/index.yaml
# ---
# schema: olm.channel
# package: sample-operator
# name: preview
# entries:
#   - name: sample-operator.v0.0.1
# EOF
# "

# pei "opm validate  sample-operator-index"
# pei " podman build . \\
#     -f sample-operator-index.Dockerfile \\
#     -t $INDEX_IMG"

# https://docs.openshift.com/container-platform/4.8/operators/admin/olm-managing-custom-catalogs.html#olm-creating-index-image_olm-managing-custom-catalogs
pei "opm index add \\
  --bundles $BUNDLE_IMG \\
  --tag $INDEX_IMG "

pei "podman push $INDEX_IMG"

pei "kubectl create -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-operator-catalog
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: $INDEX_IMG
  displayName: My Operator Catalog
  publisher: Robert Bohne
  updateStrategy:
    registryPoll:
      interval: 30m
EOF
"

pei "oc get pods -n openshift-marketplace \\
  -l olm.catalogSource=my-operator-catalog --watch"

pe "# Switch to OpenShift GUI - just for visiblity "





# podman run -p 50051:50051 -ti quay.io/openshift-examples/ansible-example-operator-index:latest
# grpcurl -plaintext localhost:50051 api.Registry/ListPackages


