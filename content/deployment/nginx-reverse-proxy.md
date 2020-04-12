# Nginx reverse proxy

Based on 

[Run Nginx as reverse proxy on Openshift](http://keyangxiang.com/2018/06/01/Openshift/how-to-run-nginx-as-reverse-proxy/)

#### Build

```bash
oc new-build openshift/nginx~https://github.com/openshift-examples/nginx-reverse-proxy.git \
  --name=nginxbase \
  --context-dir=nginx-reverse-proxy \
  --strategy=source
```

#### Build & Deploy

```bash
oc new-app https://github.com/openshift-examples/nginx-reverse-proxy.git \
  --context-dir=nginx-reverse-proxy \
  --strategy=docker \
  --name=reverse-proxy
oc expose svc/reverse-proxy
```

