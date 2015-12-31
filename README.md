A tool for configurating ForgeRocks OpenAM instances.

Ready for fullStack example of ForgeRocks Identity Stack Dockerized

This is a docker image that runs the OpenAM config tool to configure a freshly installed 
instance. The files master.properties and second.properties is used to configure the server.

https://github.com/ConductAS/identity-stack-dockerized.git

docker run --rm --link openam-svc-a --link openam-svc-b --link opendj --name ssoconfig -v /var/lib/id-stack/repo:/opt/repo conductdocker/ssoconfig-nightly

