# Purpose of this Containerfile is for local development / test only.
# Build: podman build --target builder -t mkdocs:local --no-cache .
# Run: podman run -ti --rm -v $(pwd):/opt/app-root/src:z -p 8080:8080 mkdocs:local
#
FROM quay.io/openshift-examples/builder:devel AS builder
USER root
# Copying in source code
COPY . /tmp/src/
# Change file ownership to the assemble user. Builder image must support chown command.
RUN chown -R 1001:0 /tmp/src/
USER 1001

RUN /usr/libexec/s2i/assemble

FROM registry.access.redhat.com/ubi9/nginx-120:latest
USER root

# RUN dnf -y update \
#  && dnf clean all

COPY --from=builder /opt/app-root/src/site /tmp/src
COPY --from=builder /opt/app-root/src/nginx-cfg /tmp/src/nginx-cfg

RUN chown -R 1001:0 /tmp/src
USER 1001

RUN /usr/libexec/s2i/assemble


CMD /usr/libexec/s2i/run
