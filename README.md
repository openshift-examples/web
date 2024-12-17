# Content of [examples.openshift.pub](https://examples.openshift.pub/)

![](content/images/logo-black.png)

## Development

### Git Submodules

Create a new submodule

```bash
cd content/kubevirt/
git submodule add https://github.com/openshift-examples/kubevirt-ansible ansible
```

### Builder image

```bash
podman build \
  -t mkdocs:builder \
  --no-cache \
  -f builder.Containerfile .

```

#### Run it

```bash
podman run -ti --user 0 --rm \
  -v $(pwd):/opt/app-root/src:z \
  -p 8080:8080 mkdocs:builder
```

## Stargazers over time

[![Stargazers over time](https://starchart.cc/openshift-examples/web.svg)](https://starchart.cc/openshift-examples/web)
