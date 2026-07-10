podman run -ti --rm --user 0 \
    -v $(pwd):/opt/app-root/src:z \
    quay.io/openshift-examples/builder:202604300846 \
    ./helper/run-pre-commit.sh
