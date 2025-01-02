ARG  BUILDER_IMAGE=quay.io/openshift-examples/builder:devel
FROM ${BUILDER_IMAGE} AS builder

USER root
# Copying in source code
COPY . /tmp/src/
# Change file ownership to the assemble user. Builder image must support chown command.
RUN chown -R 1001:0 /tmp/src/
USER 1001

RUN /usr/libexec/s2i/assemble

FROM registry.access.redhat.com/ubi9/nginx-124:latest
USER root

# RUN dnf -y update \
#  && dnf clean all

COPY --from=builder /opt/app-root/src/site /tmp/src
COPY --from=builder /opt/app-root/src/nginx-cfg /tmp/src/nginx-cfg

RUN chown -R 1001:0 /tmp/src
USER 1001

RUN /usr/libexec/s2i/assemble


CMD /usr/libexec/s2i/run
