# Content of [examples.openshift.pub](https://examples.openshift.pub/)

![](content/images/logo-black.png)

## Development

### Git Submodules

Create a new submodule

```bash
cd content/kubevirt/
git submodule add https://github.com/openshift-examples/kubevirt-ansible ansible
```

### Run it with public builder

```bash
podman run -ti --user 0 --rm \
  -v $(pwd):/opt/app-root/src:z \
  -p 8080:8080 quay.io/openshift-examples/builder:devel
```

### Run local pre-commit check

```bash
./run-local-pre-commit.sh
```

### Builder image

```bash
podman build \
  -t mkdocs:builder \
  --no-cache \
  -f builder.Containerfile .

```

#### Run it with local builder image

```bash
podman run -ti --user 0 --rm \
  -v $(pwd):/opt/app-root/src:z \
  -p 8080:8080 mkdocs:builder
```

## Stargazers over time

[![Stargazers over time](https://starchart.cc/openshift-examples/web.svg)](https://starchart.cc/openshift-examples/web)
