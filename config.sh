#!/usr/bin/env bash

cd /var/tmp

if [ -e "$openamconf" ]; then
	cp -rv $openamconf/* /var/tmp/
fi

cert=/opt/repo/ssl/combined.pem
if [ -s "$cert" ]; then
	export FQDN=$(openssl x509 -noout -subject -in $cert | sed "s/^.*CN=\*\./iam./" | sed "s/^.*CN=//" | sed "s/\/.*$//")
	export DOMAIN=$(echo $FQDN | sed "s/[^\.]*\.//")
	sed -i 's/iam.example.com/'"$FQDN"'/;s/example.com/'"$DOMAIN"'/' master.properties
	sed -i 's/iam.example.com/'"$FQDN"'/;s/example.com/'"$DOMAIN"'/' second.properties
fi

# Optionally pass in URL of OpenAM server

URL=${OPENAM_URL:-"http://openam-svc-a:8080/openam"}
T="$URL/config/options.htm"

echo Configuring OpenAM $T 
until [ $(curl -s -o /dev/null -w "%{http_code}" $T ) == 200 ]; do
	echo "Waiting for OpenAM server at $T "
    sleep 5
done

java -jar $openambin/*/openam-configurator-tool*.jar -f master.properties

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
	java -jar $openambin/*/openam-configurator-tool*.jar -f second.properties
fi


echo "This container has finished sucessfully!"
echo "OpenIDM https://$FQDN/"
echo "OpenIDM Admin https://$FQDN/admin/"
echo "OpenAM https://$FQDN/openam/"

while :
do
	sleep 1
done
