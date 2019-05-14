FROM rhscl/s2i-base-rhel7:latest

LABEL io.k8s.description="R Shiny" \
    io.k8s.display-name="R Shiny" \
    io.openshift.expose-services="8080:http" \
    io.openshift.tags="builder,webserver,html,r,shiny" \
    # this label tells s2i where to find its mandatory scripts
    # (run, assemble, save-artifacts)
    io.openshift.s2i.scripts-url="image:///usr/libexec/s2i"

#FROM registry.redhat.io/rhscl/s2i-base-rhel7:latest

# docker run -ti --entrypoint bash registry.redhat.io/openshift3/ose-sti-builder

# $ subscription-manager repos  \
#    --enable=rhel-7-server-rpms\
#    --enable=rhel-7-server-extras-rpms\
#    --enable=rhel-7-server-optional-rpms\

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum-config-manager --enable rhel-7-server-optional-rpms
# Install R
RUN yum -y install R
# Hack, I don't know why: html directory does not exist.
RUN mkdir -v /usr/share/doc/$(R -s -e 'f <- R.Version(); cat(sprintf("R-%s.%s",f[6],f[7]))')/html

# Hack, install libxml2-devel for R module tm
RUN yum -y install libxml2-devel


# $ R -s -e "print(R.home(component='home'))"
# [1] "/usr/lib64/R"
# cat /usr/lib64/R/etc/Rprofile.site
# local({
#   r <- getOption("repos")
#   r["CRAN"] <- "http://cran.rstudio.com/"
#   options(repos = r)
# })
COPY Rprofile.site /usr/lib64/R/etc/

RUN mkdir /opt/app-root/R/
RUN chmod -R g+w /opt/app-root/R/
ENV R_LIBS_USER=/opt/app-root/R/

RUN R -s -e "install.packages('shiny', repos = 'http://cran.rstudio.com/' )"
RUN R -s -e "install.packages('remotes', repos = 'http://cran.rstudio.com/' )"
RUN R -s -e "remotes::install_github('MilesMcBain/deplearning')"

COPY ./s2i/bin/ /usr/libexec/s2i

USER 1001

# Set the default port for applications built using this image
EXPOSE 8080

CMD ["/usr/libexec/s2i/usage"]