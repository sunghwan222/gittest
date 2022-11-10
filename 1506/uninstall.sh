#!/bin/bash
#
# uninstall.sh
##!/bin/bash
#
# uninstall.sh
#
# Created on: 24 Feb 2020
# Target: Linux debian distros machines
#
# Endpoint Protector offers Data Loss Prevention for Windows, Mac and Linux, as well as
# Mobile Device Management for Android and iOS.
#

readonly _current_user="$(whoami)"
readonly _epp_client_daemon=epp-client-daemon-d
readonly _epp_client_installed="$(dpkg -l | grep epp-client | awk '{print $3}' | head -1)"

readonly _yellow_color="\e[1;33m"
readonly _red_color='\e[1;31m'
readonly _white_color='\e[1;37m'

echo -e "$_white_color The current user is $_current_user"

## Begin the epp-client uninstallation with prerequisites
echo
echo -e "$_yellow_color Begin the epp-client uninstallation with prerequisite. $_white_color"

## Check if the epp-client is already installed  on this machine
echo -e "$_yellow_color Check if the epp-client is already installed  on this machine. $_white_color"
if [ "$_epp_client_installed" != "" ]; then
	echo "The epp-client is installed. Proceeding with uninstalling."
	echo "Stopping $_epp_client_daemon"
	sudo service $_epp_client_daemon stop
	echo "Uninstalling the epp-client."
	sudo /usr/bin/crontab -l | grep -v '/opt/cososys/check-eppclient-process.sh' | /usr/bin/crontab -
	sudo kill -s KILL $(ps aux | grep [e]pp-client | awk '{print $2}') 2>/dev/null
	sudo kill -s KILL $(ps aux | grep [c]heck-eppclient-process.sh | awk '{print $2}') 2>/dev/null
	sudo rm -rf /opt/cososys
	sudo rm -rf /var/opt/cososys
	sudo rm -rf /var/log/epp-client
	sudo dpkg --purge epp-client
	sudo rm -f /etc/init.d/epp-client-daemon-d
	sudo dpkg --purge epp-client-config
	sudo dpkg --purge epp-client-cap-def
	sudo dpkg --purge cososys-filesystem
	echo
	echo -e "The epp-client is successfully uninstalled."
	exit
else
	echo -e "$_yellow_color The epp-client  package is not installed on this machine. Nothing to do... $_white_color"
fi

exit
