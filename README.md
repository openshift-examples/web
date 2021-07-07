# Content of [examples.openshift.pub](https://examples.openshift.pub/)

![](content/images/logo-black.png)

## Build

### via Containerfile

Export `GH_TOKEN` with access to `github.com/squidfunk/mkdocs-material-insiders.git`.
In case you don't have access to material-insiders it will build with material.

```bash
podman build \
  -t mkdocs:local \
  --no-cache \
  --build-arg GH_TOKEN=${GH_TOKEN} \
  -f Containerfile .

```

### Local development

#### Build local runtime.

Export `GH_TOKEN` with access to `github.com/squidfunk/mkdocs-material-insiders.git`.
In case you don't have access to material-insiders it will build with material.

```bash
podman build \
  -t mkdocs:local \
  --no-cache \
  --build-arg GH_TOKEN=${GH_TOKEN} \
  -f Containerfile.local-run .

```

#### Run it

```bash
podman run -ti --rm \
  -v $(pwd):/opt/app-root/src:z \
  -p 8080:8080 mkdocs:local
```

## Stargazers over time

![Stargazers over time](https://starcharts.herokuapp.com/rbo/openshift-examples.svg)

