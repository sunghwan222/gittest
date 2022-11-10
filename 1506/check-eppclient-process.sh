#!/bin/bash

OUT=/dev/null

function checkdaemon()
{
	if ps aux | grep "[/]opt/cososys/sbin/epp-client-daemon" > $OUT
	then
		echo "$1 [epp-client-daemon]: Running" > $OUT
	else
		echo "$1 [epp-client-daemon]: Stopped! Starting ip up again!" > $OUT
		/etc/init.d/epp-client-daemon-d restart > $OUT 2>&1
	fi
}

while true
do
	NOW=$(date +"%X")
	if [ $(pgrep -f check-eppclient-process.sh | wc -w) -gt 2 ]; then
		echo "$NOW More than one check_eppclient_process.sh instance is running, exiting..." > $OUT
		exit
	fi
	checkdaemon $NOW
	sleep 5;
done

