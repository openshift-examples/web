podman run -ti --rm -v \
    $(pwd):/opt/app-root/src quay.io/openshift-examples/builder:202511251107 \
    ./helper/run-pre-commit.sh