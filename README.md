# Content of [examples.openshift.pub](https://examples.openshift.pub/)

![](content/images/logo-black.png)

## Development

### Git Submodules

Create a new submodule

```shell
cd content/kubevirt/
git submodule add https://github.com/openshift-examples/kubevirt-ansible ansible
```

### Run local

```shell
./run-local.sh
```

Run local pre-commit via: `./run-local-pre-commit.sh`

### Build & push new builder image

```shell
export VERSION=$(date +%Y%m%d%H%M)
export IMAGE=quay.io/openshift-examples/builder:${VERSION}

podman manifest rm ${IMAGE}

podman build \
  --platform linux/amd64,linux/arm64 \
  --manifest ${IMAGE} \
  --no-cache \
  -f builder.Containerfile .

podman manifest push ${IMAGE}
```

## Stargazers over time

[![Stargazers over time](https://starchart.cc/openshift-examples/web.svg)](https://starchart.cc/openshift-examples/web)
