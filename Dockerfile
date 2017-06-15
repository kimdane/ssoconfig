# Docker image for the OpenAM configurator tool
FROM java:8

MAINTAINER kim@conduct.no
WORKDIR /var/tmp

COPY master.properties /var/tmp/
COPY second.properties /var/tmp/
COPY config.sh /var/tmp/

VOLUME ["/opt/repo"]
RUN sed 's/iam.example.com/'$(openssl x509 -noout -subject -in /opt/repo/ssl/combined.pem | sed "s/^.*CN=\*\./iam./" | sed "s/^.*CN=//" | sed "s/\/.*$//")'/' /tmp/master.properties
RUN sed 's/iam.example.com/'$(openssl x509 -noout -subject -in /opt/repo/ssl/combined.pem | sed "s/^.*CN=\*\./iam./" | sed "s/^.*CN=//" | sed "s/\/.*$//")'/' /tmp/second.properties

CMD ["/var/tmp/config.sh"]

