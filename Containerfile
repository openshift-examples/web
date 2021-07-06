# Purpose of this Containerfile is for local development / test only.
# Build: podman build -t mkdocs:local --no-cache --build-arg GH_TOKEN=${GH_TOKEN} -f Containerfile.local-run .
# Run: podman run -ti --rm -v $(pwd):/opt/app-root/src:z -p 8080:8080 mkdocs:local
#
FROM registry.access.redhat.com/ubi8/python-38:latest AS builder
LABEL "io.openshift.s2i.build.image"="registry.access.redhat.com/ubi8/python-38:latest" \
      "io.openshift.s2i.build.commit.author"="Robert Bohne <robert.bohne@redhat.com>"

USER root
ARG GH_TOKEN


# # Copying in source code
COPY . /tmp/src
# # Change file ownership to the assemble user. Builder image must support chown command.
RUN chown -R 1001:0 /tmp/src
USER 1001

RUN if [[ ! -z "$GH_TOKEN" ]] ; then \
      mv /tmp/src/requirements-insider.txt /tmp/src/requirements.txt;\
      # pip install -r /tmp/src/requirements-insider.txt; \
    else \
      echo "#";\
      echo "# Build without mkdocs material insider!"; \
      echo "#";\
      # pip install -r /tmp/src/requirements.txt; \
    fi

RUN /usr/libexec/s2i/assemble

RUN mkdocs build --clean

FROM registry.access.redhat.com/ubi8/nginx-118:latest
USER root

COPY --from=builder /opt/app-root/src/site /tmp/src
COPY --from=builder /opt/app-root/src/nginx-cfg /tmp/src/nginx-cfg

RUN chown -R 1001:0 /tmp/src
USER 1001

RUN /usr/libexec/s2i/assemble

CMD /usr/libexec/s2i/run
