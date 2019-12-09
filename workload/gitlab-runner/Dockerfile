# FROM registry.access.redhat.com/ubi8-minimal
FROM registry.access.redhat.com/ubi8/ubi-minimal

LABEL maintainer="Robert Bohne"
ENV HOME='/runner/'

RUN microdnf update -y && rm -rf /var/cache/yum
RUN microdnf install nss_wrapper gettext tar gzip -y \
    && microdnf clean all

RUN curl -L -s \
    https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux-4.2.9.tar.gz \
    | tar -C /usr/local/bin/ -zxv oc kubectl ; \
    chmod +x /usr/local/bin/oc ; \
    chmod +x /usr/local/bin/kubectl

RUN curl -L -# \
    --output /usr/local/bin/gitlab-runner \
    https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64 ; \
    chmod +x /usr/local/bin/gitlab-runner

RUN mkdir /container-scripts/ && cp /etc/passwd /container-scripts/ && chmod 666 /container-scripts/passwd
RUN mkdir -p /runner/.gitlab-runner/ && chmod -R 777 /runner

ADD container-scripts/* /container-scripts/

ENTRYPOINT ["/container-scripts/entrypoint.sh"]