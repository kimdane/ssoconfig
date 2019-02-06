# Docker image for the OpenAM configurator tool
FROM java:8

MAINTAINER kimdane
WORKDIR /var/tmp

ENV openambin=/opt/repo/bin/openam
ENV openamconf=/opt/repo/ssoconfig/
ENV openamzip=/opt/repo/bin/zip/openam.zip

COPY master.properties /var/tmp/
COPY second.properties /var/tmp/
COPY config.sh /var/tmp/

VOLUME ["/opt/repo"]

CMD ["/var/tmp/config.sh"]

