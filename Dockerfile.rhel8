FROM registry.access.redhat.com/ubi8/python-36:latest AS builder
LABEL "io.openshift.s2i.build.image"="registry.access.redhat.com/ubi8/python-36:latest" \
      "io.openshift.s2i.build.commit.author"="Robert Bohne <robert.bohne@redhat.com>" 

USER root
# Copying in source code
COPY . /tmp/src
# Change file ownership to the assemble user. Builder image must support chown command.
RUN chown -R 1001:0 /tmp/src
USER 1001
# Assemble script sourced from builder image based on user input or image metadata.
# If this file does not exist in the image, the build will fail.
RUN /usr/libexec/s2i/assemble

RUN mkdocs build --clean

FROM registry.redhat.io/rhel8/nginx-116:latest
COPY --from=builder /opt/app-root/src/site /opt/app-root/src
CMD /usr/libexec/s2i/run