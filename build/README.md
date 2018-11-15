# Build examples

## Builder -> Runner image

```
# Important to build with an older tag

oc import-image openjdk18-openshift:latest --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift --confirm
oc import-image openjdk18-openshift:1.0 --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift:1.0 --confirm

oc new-build --name=build-with-1 --image-stream=openjdk18-openshift:1.0 https://github.com/rbo/chaos-professor.git


echo -e "FROM openjdk18-openshift \nCOPY chaos-professor-0.0.1.jar /deployments/" | oc new-build --name=run-with-latest-1 \
    --image-stream=openjdk18-openshift:latest \
    --source-image=build-with-1 \
    --source-image-path=/tmp/src/target/chaos-professor-0.0.1.jar:. \
    --strategy=docker \
    --dockerfile -

oc new-app build-with-1 && oc expose svc/build-with-1
oc new-app run-with-latest-1 && oc expose svc/run-with-latest-1
```
