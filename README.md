# Content of examples.openshift.pub

![](content/images/logo-black.png)

## Build site

### Source-to-Image

```bash
s2i build  https://github.com/openshift-examples/example.openshift.pub.git \
  registry.access.redhat.com/ubi8/python-36:latest \
  --as-dockerfile openshift-examples \
  --env APP_SCRIPT=start-mkdocs.sh

podman build -t openshift-examples:latest -f openshift-examples .
podman run -p 8080:8080 openshift-examples:latest
```

