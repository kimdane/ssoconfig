#!/usr/bin/env bash

cd /var/tmp

dir=/opt/repo/ssoconfig
if [ -e "$dir" ]; then
	rm master.properties
	rm second.properties
	cp -rv /opt/repo/ssoconfig/* .
	export FQDN=$(openssl x509 -noout -subject -in /opt/repo/ssl/combined.pem | sed "s/^.*CN=\*\./iam./" | sed "s/^.*CN=//" | sed "s/\/.*$//")
	export DOMAIN=$(echo $FQDN | sed "s/[^\.]*\.//")
	cat master.properties | sed 's/iam.example.com/'$DOMAINNAME'/' | sed 's/example.com/'$DOMAIN'/' > master.properties
	cat second.properties | sed 's/iam.example.com/'$DOMAINNAME'/' | sed 's/example.com/'$DOMAIN'/' > second.properties
fi

file=/opt/repo/bin/staging/configurator.zip
echo $(pwd)
ls
if [ -s "$file" ]; then
		cp "$file" configurator.zip
else
	# Download AM 13 configurator from maven build
	curl http://maven.forgerock.org/repo/simple/snapshots/org/forgerock/openam/openam-distribution-ssoconfiguratortools/13.0.0-SNAPSHOT/ \
   | grep -o 'href=.*\.zip\"' | grep -o 'openam.*zip' | \
 	xargs -I % curl -o /var/tmp/configurator.zip  \
 	http://maven.forgerock.org/repo/simple/snapshots/org/forgerock/openam/openam-distribution-ssoconfiguratortools/13.0.0-SNAPSHOT/%
fi
unzip configurator.zip

# Optionally pass in URL of OpenAM server

URL=${OPENAM_URL:-"http://openam-svc-a:8080/openam"}
T="$URL/config/options.htm"

echo Configuring OpenAM $T 
until [ $(curl -s -o /dev/null -w "%{http_code}" $T ) == 200 ]; do
	echo "Waiting for OpenAM server at $T "
    sleep 5
done

java -jar openam-configurator-tool*.jar -f master.properties

URL2=${OPENAM_URL:-"http://openam-svc-b:8080/openam"}
T="$URL2/config/options.htm"

# Removing this until we do multiple OpenAMs
#echo Configuring OpenAM $T 
TRY=10
until [ $(curl -s -o /dev/null -w "%{http_code}" $T ) == 200 ] || [ $TRY -gt 9 ]; do
	echo "Waiting for OpenAM server at $T "
    sleep 5
	let "TRY++"
done
if [ $TRY -lt 9 ]; then	
	java -jar openam-configurator-tool*.jar -f second.properties
fi


echo "This container has finished sucessfully!"
while :
do
	sleep 1
done
