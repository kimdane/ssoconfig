#!/usr/bin/env bash

cd /var/tmp

dir=/opt/repo/ssoconfig
if [ -e "$dir" ]; then
	cp -rv /opt/repo/ssoconfig/* .
fi

file=/opt/repo/bin/staging/configurator.zip
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

echo Configuring OpenAM $T 
TRY=0
until [ $(curl -s -o /dev/null -w "%{http_code}" $T ) == 200 ] || [ $TRY -gt 9 ]; do
	echo "Waiting for OpenAM server at $T "
    sleep 5
	let "TRY++"
done

java -jar openam-configurator-tool*.jar -f second.properties

