#!/bin/bash
# 
# check-eppclient-process.sh
#
#	Created on: 12 Jul 2020
#	Vendor: CoSoSys Endpoint Protector
#	Url: http:/www.EndpointProtector.com
#
#	Bash coding conventions and good practices:
#		https://github.com/icy/bash-coding-style#variable-names
#


readonly _ps=/bin/ps
readonly _echo=/bin/echo
readonly _grep=/bin/grep
readonly _date=/bin/date

if [ -f /usr/bin/pgrep ]; then
	readonly _pgrep=/usr/bin/pgrep
else
	readonly _pgrep=/bin/pgrep
fi

if [ -f /usr/bin/wc ]; then
	readonly _wc=/usr/bin/wc 
else
	readonly _wc=/bin/wc
fi

while true
do
	_now=$(${_date} +"%X")

	if [ $($_pgrep -f check-eppclient-process.sh | $_wc -w) -gt 3 ]
	then
		$_echo "  [$_now][check_eppclient_process.sh]: More than one instance is running, exiting..."
		exit
	fi

	if [ $($_pgrep -f epp-client-daemon | $_wc -w) -gt 0 ]
	then
		# $_echo  "  [$_now][check_eppclient_process.sh]: Running."
		true
	else
		$_echo "  [$_now][check_eppclient_process.sh]: Stopped. Starting it up again!"
		/etc/init.d/epp-client-daemon-d restart
	fi

	sleep 5;
done
