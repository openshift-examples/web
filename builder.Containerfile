# Purpose of this Containerfile is for local development / test only.
# Build: podman build --target builder -t mkdocs:local --no-cache .
# Run: podman run -ti --rm -v $(pwd):/opt/app-root/src:z -p 8080:8080 mkdocs:local
#
FROM registry.access.redhat.com/ubi9/python-312:latest AS builder
LABEL "io.openshift.s2i.build.image"="registry.access.redhat.com/ubi9/python-39:latest" \
      "io.openshift.s2i.build.commit.author"="Robert Bohne <robert.bohne@redhat.com>"

USER root

# Install gem for pre-commit
RUN dnf -y update \
 && dnf -y install gem ruby-devel\
 && dnf clean all

# Copying in source code
COPY requirements.txt /tmp/src/
# Change file ownership to the assemble user. Builder image must support chown command.
RUN chown -R 1001:0 /tmp/src
USER 1001

RUN /usr/libexec/s2i/assemble && rm /opt/app-root/src/requirements.txt

USER root
ADD builder.assemble /usr/libexec/s2i/assemble
# https://github.com/pre-commit/pre-commit/issues/2799#issuecomment-1581753428
RUN rm -f /usr/share/rubygems/rubygems/defaults/operating_system.rb
USER 1001

EXPOSE 8080/tcp
WORKDIR /opt/app-root/src
CMD mkdocs serve --dev-addr 0.0.0.0:8080 --no-livereload
