# Setup cpu based autoscaling

```
oc process -f pod_autoscaling_template.json  | oc create -f -
```

# Test autoscaling

```
# Only 4fun
ab 'http://choas-professor-omd.paas.osp.consol.de/chaos-professor-0.0.1/chaos/heapheap?size=500&time=10000'
ab 'http://choas-professor-omd.paas.osp.consol.de/chaos-professor-0.0.1/chaos/cpu?threads=100&keepAlive=20000'
ab -c 10 -n 100 'http://choas-professor-omd.paas.osp.consol.de/chaos-professor-0.0.1/chaos/cpu?threads=100&keepAlive=200'
```

# Delete all
```
oc get all -o name | xargs -n1  oc delete
oc delete hpa/choas-professor
```
