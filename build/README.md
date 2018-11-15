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

## Add git config 


[OpenShift 3.11 documenation](https://docs.openshift.com/container-platform/3.11/dev_guide/builds/build_inputs.html#source-secrets-gitconfig-file-secured)


Create ```/tmp/gitconfig```

```ini
[http]
    sslVerify = false
# Just for information:
[core]
    sshCommand = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
```

Run commands: ( Create secret & add ```--source-secret=build``` to new-build )
```sh
oc create secret generic build --from-file=.gitconfig=/tmp/gitconfig \
    --from-file=ssh-privatekey=/tmp/github_rsa \
    --type=kubernetes.io/ssh-auth

oc new-build registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift~git@github.com:rbo/chaos-professor.git --source-secret=build --env BUILD_LOGLEVEL=5

# If you like, create app
oc new-app chaos-professor
```