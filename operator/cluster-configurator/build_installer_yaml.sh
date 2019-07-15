#!/usr/bin/env bash


cat <<EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-rbo-configurator
  labels:
    name: openshift-rbo-configurator
---
EOF

cat deploy/crds/clusterconfig_v1alpha1_clusterconfigurator_crd.yaml
echo "---"
# cat deploy/role.yaml
# echo "---"
cat deploy/role_binding.yaml
echo "---"
cat deploy/service_account.yaml
echo "---"
cat deploy/operator.yaml
