#!/bin/bash

set -eu

# Set current user in nss_wrapper
passwd_output_dir="${HTTPD_APP_ROOT}/etc"
mkdir -p ${passwd_output_dir}
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < ${HTTPD_CONTAINER_SCRIPTS_PATH}/passwd.template > ${passwd_output_dir}/passwd
export LD_PRELOAD=libnss_wrapper.so
export NSS_WRAPPER_PASSWD=${passwd_output_dir}/passwd
export NSS_WRAPPER_GROUP=/etc/group


exec httpd -D FOREGROUND $@