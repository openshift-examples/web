podman run -ti --rm -v \
    $(pwd):/opt/app-root/src quay.io/openshift-examples/builder:devel \
    ./helper/run-pre-commit.sh