podman run -ti --user 0 --rm \
  -v $(pwd):/opt/app-root/src:z \
  -p 8080:8080 quay.io/openshift-examples/builder:202511251107

