FROM centos:7
# docker run -ti registry.redhat.io/rhel7:7.6 bash
# https://github.com/sclorg/httpd-container

ENV HTTPD_CONTAINER_SCRIPTS_PATH=/container-scripts/ \
    HTTPD_APP_ROOT=/app \
    HTTPD_CONFIGURATION_PATH=${APP_ROOT}/etc/httpd.d \
    HTTPD_MAIN_CONF_PATH=/etc/httpd/conf \
    HTTPD_MAIN_CONF_MODULES_D_PATH=/etc/httpd/conf.modules.d \
    HTTPD_MAIN_CONF_D_PATH=/etc/httpd/conf.d \
    HTTPD_VAR_RUN=/run/httpd

RUN yum install -y yum-utils epel-release && \
    INSTALL_PKGS="httpd nss_wrapper gettext" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum -y clean all --enablerepo='*'

ADD container-scripts/* /container-scripts/

RUN sed -i -e 's/^Listen 80/Listen 0.0.0.0:8080/' ${HTTPD_MAIN_CONF_PATH}/httpd.conf && \
    chmod 644 ${HTTPD_MAIN_CONF_PATH}/* && \
    chmod 755 ${HTTPD_MAIN_CONF_PATH} && \
    chmod 644 ${HTTPD_MAIN_CONF_D_PATH}/* && \
    chmod 755 ${HTTPD_MAIN_CONF_D_PATH} && \
    chmod 644 ${HTTPD_MAIN_CONF_MODULES_D_PATH}/* && \
    chmod 755 ${HTTPD_MAIN_CONF_MODULES_D_PATH} && \
    chmod 777 ${HTTPD_VAR_RUN} && \
    chmod 777 /var/log/httpd/ && \
    sed -i -e "s/^User apache/User default/" ${HTTPD_MAIN_CONF_PATH}/httpd.conf  && \
    sed -i -e "s/^Group apache/Group root/" ${HTTPD_MAIN_CONF_PATH}/httpd.conf && \
    chmod +x /container-scripts/entrypoint.sh && \
    mkdir ${HTTPD_APP_ROOT} && \
    chmod 775   ${HTTPD_APP_ROOT} 


# docker build . -f Dockerfile.anyuid -t httpd && docker run -ti -p 8080:8080 --user 1234 --entrypoint bash httpd

EXPOSE 8080

VOLUME [ "/var/www/html/" ]
USER 1984
# https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact
ENTRYPOINT ["/container-scripts/entrypoint.sh"]