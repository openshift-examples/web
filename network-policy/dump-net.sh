#!/usr/bin/env bash

if [ "$1" == "" -o "$2" == "" ] ; then
  echo "Please run ./$0 <NODE> <FILE>";
  exit 1;
fi;

NODE=$1
DUMP_FILE=$2
# RUN_AT=$(date +%Y-%m-%d-%H-%M-%S.%s)
PODS=$(oc get pods -n openshift-sdn  -l app=sdn -o go-template='{{range .items}}{{.spec.nodeName}};{{.metadata.name}}{{"\n"}}{{end}}' | grep ^${NODE});
echo "Run dump at $PODS";

for i in $PODS ; do
    NODE=${i%;*}
    POD=${i#*;}
    # DUMP_FILE=dump.${RUN_AT}.${NODE}.txt
    echo "Write: ${DUMP_FILE}.OpenFlow13"
    oc rsh -n openshift-sdn pod/${POD} ovs-ofctl -O OpenFlow13 --no-stats dump-flows br0 | perl -pe 's/(reg0|reg1)=([^ ,]+)/sprintf("%s=%d",$1, hex($2))/eg' > ${DUMP_FILE}.OpenFlow13
    echo "Write: ${DUMP_FILE}.iptables"
    oc rsh -n openshift-sdn pod/${POD} iptables-save > ${DUMP_FILE}.iptables
done;