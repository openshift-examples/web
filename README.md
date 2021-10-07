# Content of [examples.openshift.pub](https://examples.openshift.pub/)

![](content/images/logo-black.png)

## Build

### via Containerfile

```bash
podman build \
  -t mkdocs:local \
  --no-cache \
  -f Containerfile .

```

### Local development

#### Build local runtime.

```bash
podman build \
  -t mkdocs:local \
  --no-cache \
  -f Containerfile.local-run .

```

#### Run it

```bash
podman run -ti --rm \
  -v $(pwd):/opt/app-root/src:z \
  -p 8080:8080 mkdocs:local
```

## Stargazers over time

[![Stargazers over time](https://starchart.cc/openshift-examples/web.svg)](https://starchart.cc/openshift-examples/web)

