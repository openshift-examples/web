FROM registry.redhat.io/rhel7
# docker build . --build-arg RH_ORG_ID=...
# ***REMOVED***
ARG RH_ORG_ID 
***REMOVED***
ARG RH_ACTIVATIONKEY
# ***REMOVED***
ARG RH_POOL_ID

RUN subscription-manager register --org=$RH_ORG_ID --activationkey=$RH_ACTIVATIONKEY  && \
    subscription-manager attach --pool=$RH_POOL_ID && \
    subscription-manager repos --disable="*" && \
    subscription-manager repos \
        --enable="rhel-7-server-rpms" \
        --enable="rhel-7-server-extras-rpms" \
        --enable="rhel-7-server-ose-3.11-rpms" \
        --enable="rhel-7-server-ansible-2.6-rpms"

RUN yum install -y skopeo openssl docker-distribution tmux lsof telnet

VOLUME /work
WORKDIR /work

ENTRYPOINT bash

USER 0
