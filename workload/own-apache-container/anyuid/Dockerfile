FROM registry.access.redhat.com/rhel7/rhel:7.6
# docker run -ti registry.redhat.io/rhel7:7.6 bash

RUN yum install -y httpd && \
    yum clean -y all && \
    rm -rf   /var/cache/yum/*

RUN sed -i -e 's/^Listen 80/Listen 0.0.0.0:8080/' /etc/httpd/conf/httpd.conf


# docker build . -f Dockerfile.anyuid -t httpd && docker run -ti -p 8080:8080 --user 1234 --entrypoint bash httpd

EXPOSE 8080

VOLUME [ "/var/www/html/" ]

# https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
ENTRYPOINT ["httpd","-DFOREGROUND"]