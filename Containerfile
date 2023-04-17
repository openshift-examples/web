# Purpose of this Containerfile is for local development / test only.
# Build: podman build --target builder -t mkdocs:local --no-cache .
# Run: podman run -ti --rm -v $(pwd):/opt/app-root/src:z -p 8080:8080 mkdocs:local
#
FROM registry.access.redhat.com/ubi9/python-39:latest AS builder
LABEL "io.openshift.s2i.build.image"="registry.access.redhat.com/ubi9/python-39:latest" \
      "io.openshift.s2i.build.commit.author"="Robert Bohne <robert.bohne@redhat.com>"

USER root

# Install gem for pre-commit
RUN dnf -y update \
 && dnf -y install gem \
 && dnf clean all

# Copying in source code
COPY . /tmp/src
# Change file ownership to the assemble user. Builder image must support chown command.
RUN chown -R 1001:0 /tmp/src
USER 1001

RUN /usr/libexec/s2i/assemble

ENV PRE_COMMIT_HOME=/tmp/
RUN pre-commit install-hooks

# Disabled, we have to cleanup first...
# RUN pre-commit run --color=never --all-files

RUN mkdocs build --clean

VOLUME /opt/app-root/src
EXPOSE 8080/tcp
CMD mkdocs serve --dev-addr 0.0.0.0:8080 --no-livereload

FROM registry.access.redhat.com/ubi9/nginx-120:latest
USER root

RUN dnf -y update \
 && dnf clean all

COPY --from=builder /opt/app-root/src/site /tmp/src
COPY --from=builder /opt/app-root/src/nginx-cfg /tmp/src/nginx-cfg

RUN chown -R 1001:0 /tmp/src
USER 1001

RUN /usr/libexec/s2i/assemble

CMD /usr/libexec/s2i/run
