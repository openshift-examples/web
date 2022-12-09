FROM registry.access.redhat.com/ubi9:latest

RUN dnf install -y gem python3-pip git && \
    pip install pre-commit


WORKDIR /workdir
CMD pre-commit run --color=never --all-files
