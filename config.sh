#!/usr/bin/env bash

cd /var/tmp

if [ -e "$openamconf" ]; then
	cp -rv $openamconf/* /var/tmp/
fi

jarfile=/var/tmp/ssoconfig.jar

if [ ! -e "$openambin" ] && [ -s "$openamzip" ]; then
	echo "Unzipping $openamzip"
	unzip -qn $openamzip -d /opt/repo/bin
fi
if [ -e "$openambin" ]; then
	cp -rv $openambin/*/openam-configurator-tool*.jar ssoconfig.jar
	if [ ! -s "$jarfile" ]; then
		for zipfile in $(ls $openambin/*.zip); do 
			echo "Unzipping $zipfile"
			unzip -qn $zipfile -d $openambin/tools
		done
		cp -rv $openambin/*/openam-configurator-tool*.jar ssoconfig.jar
	fi
	ls $openambin/*/openam-configurator-tool*.jar
fi
if [ -s "$jarfile" ]; then
	echo "SSOConfig succesfully extracted."
else
	echo "Did not find any openam folder at $openambin with file openam-configurator-tool*.jar in it, and don't have any open access to zipfile $openamzip"	
	exit 1
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
TRY=8
until [ $(curl -s -o /dev/null -w "%{http_code}" $T ) == 200 ] || [ $TRY -gt 9 ]; do
	echo "Waiting for OpenAM server at $T "
    sleep 5
	let "TRY++"
done

java -jar ssoconfig.jar -f master.properties

URL2=${OPENAM_URL:-"http://openam-svc-b:8080/openam"}
T="$URL2/config/options.htm"

# Removing this until we do multiple OpenAMs
#echo Configuring OpenAM $T 
TRY=6
until [ $(curl -s -o /dev/null -w "%{http_code}" $T ) == 200 ] || [ $TRY -gt 9 ]; do
	echo "Waiting for OpenAM server at $T "
    sleep 5
	let "TRY++"
done
if [ $TRY -lt 5 ]; then	
	java -jar ssoconfig.jar -f second.properties
fi


echo "This container has finished sucessfully!"
echo "OpenIDM https://$FQDN/"
echo "OpenIDM Admin https://$FQDN/admin/"
echo "OpenAM https://$FQDN/openam/"

while :
do
	sleep 1
done
