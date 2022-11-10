#!/bin/bash
#
# install.sh
#
# Created on: 21 Feb 2020
# Target: Linux debian distros machines
#
# Endpoint Protector offers Data Loss Prevention for Windows, Mac and Linux, as well as
# Mobile Device Management for Android and iOS.
#

## Define variables used by install.sh script
readonly _arch="$(/bin/uname -m)"
readonly _path_build=$(dirname $0)
readonly _epp_client_daemon=epp-client-daemon-d
readonly _dependencies_path=$_path_build/deps
readonly _packages_path=$_path_build/pkgs
readonly _configuration_path=/opt/cososys/share/apps/epp-client
readonly _configuration_file=options.ini
readonly _check_eppclient_process_sh=/opt/cososys/check-eppclient-process.sh
readonly _epp_client_status="$(dpkg -l | grep 'epp-client' | awk '{print $1}' | head -1)"
readonly _epp_client_cap_def_status="$(dpkg -l | grep 'epp-client-cap-def' | awk '{print $1}' | head -1)"
readonly _epp_client_config_status="$(dpkg -l | grep 'epp-client-config' | awk '{print $1}' | head -1)"
readonly _cososys_filesystem_status="$(dpkg -l | grep 'cososys-filesystem' | awk '{print $1}' | head -1)"
readonly _current_user="$(whoami)"
readonly _epp_notifier=/opt/cososys/bin/epp-client

readonly _yellow_color="\e[1;33m"
readonly _red_color='\e[1;31m'
readonly _white_color='\e[1;37m'

echo -e "$_white_color The current user is $_current_user"

## Check if epp-client is installed
echo
echo -e "$_yellow_color Check if the epp-client is already installed $_white_color"

if [ "$_epp_client_status" == 'ii' ] && [ "$_epp_client_cap_def_status" == 'ii' ] &&
	[ "$_epp_client_config_status" == 'ii' ] && [ "$_cososys_filesystem_status" == 'ii' ]; then

	echo -e "$_white_color The epp-client is installed. Updating options.ini"
	echo -e "$_white_color Stopping $_epp_client_daemon"
	sudo service $_epp_client_daemon stop
	echo -e "$_white_color Changing $_configuration_path/$_configuration_file with content:"
	cat $_path_build/$_configuration_file
	sudo chmod 777 $_configuration_path/$_configuration_file
	cat $_path_build/$_configuration_file >$_configuration_path/$_configuration_file
	echo -e "$_white_color Starting $_epp_client_daemon"
	sudo service $_epp_client_daemon start > /dev/null 2>& 1 &
	exit
else
	echo -e "$_white_color The epp-client is not installed on this machine."
fi

## Begin to install dependencies
echo
echo -e "$_yellow_color Begin to install dependencies $_white_color"

_list_dependencies=" "
for _entry_list_dependencies in $(ls $_dependencies_path); do
	_program_package=$(echo "$_entry_list_dependencies" | sed 's/_[0-9].*//')
	sudo dpkg -s $_program_package &>/dev/null
	if [ $? -eq 0 ]; then
		echo -e "$_white_color Package $_program_package is already installed."
	else
		echo -e "$_white_color Package $_program_package will be installed."
		_new_list_dependencies="$_list_dependencies $_dependencies_path/$_entry_list_dependencies"
		_list_dependencies=$_new_list_dependencies
	fi
done

echo -e "$_white_color Installing CoSoSys related packages for epp-client."

if [ "$_list_dependencies" == " " ]; then
	echo -e "$_white_color All dependencies are already installed."
	_dpkg_error=0
else
	echo -e "$_white_color paths = $_list_dependencies"
	sudo dpkg -i $_list_dependencies
	_dpkg_error=$?
fi

if [ $_dpkg_error -ne 0 ]; then
	echo -e "$_red_color Error: installing epp packages. Exiting... $_white_color"
	exit $_dpkg_error
fi

## Begin to install packages for epp-client
echo
if [ "$_arch" == "x86_64" ]; then
	echo -e "$_yellow_color Installing x86_64 (64b) packages. $_white_color"
else
	echo -e "$_yellow_color Installing i386 (32b) packages. $_white_color"
fi

_failed=0
sudo dpkg -i $_packages_path/cososys-filesystem_*.deb || _failed=1
sudo dpkg -i $_packages_path/epp-client-cap-def_*.deb || _failed=1
sudo dpkg -i $_packages_path/epp-client-config_*.deb  || _failed=1

## Exit with error if any of the above failed
if [ "$_failed" -ne 0 ]; then
	echo -e "$_red_color Error installing epp packages. Exiting... $_white_color"
	exit
fi

echo -e "$_white_color Changing config file to match IP/PORT/Department with provided values."
echo -e "$_white_color $_path_build/$_configuration_file"
sudo cp $_path_build/$_configuration_file $_configuration_path/$_configuration_file

# gdebi installs .deb packages with automatic depenencies
sudo apt install -y gdebi
sudo gdebi -n $_packages_path/epp-client_*.deb 2>/dev/null

_exit_code=$?
if [ $_exit_code -ne 0 ]; then
	echo -e "$_red_color Error: installing epp packages. Exiting... $_white_color"
	exit $_exit_code
fi

sudo cp $_path_build/check-eppclient-process.sh $_check_eppclient_process_sh

## Config and restart crotab
echo
echo -e "$_yellow_color Config and restart crontab $_white_color"

sudo chmod 755 $_check_eppclient_process_sh
sudo crontab -l | sudo grep '/opt/cososys/check-eppclient-process.sh' || (
	sudo /usr/bin/crontab -u root -l
	/bin/echo "* * * * * /opt/cososys/check-eppclient-process.sh &> /dev/null 2>&1"
) | sudo crontab -u root - 2>/dev/null

sudo systemctl daemon-reload

echo
echo -e "$_yellow_color The epp-client was successfully installed. $_white_color"


## If the user is not root then the epp-client notifier is launched
echo
if [[ "$EUID" -ne 0 ]]; then
	echo -e "$_yellow_color Activate the client notifier that can be accessed from system tray.  $_white_color"
	# put the epp-client notifier to run in backgroud and make the shell not wait for completion
	nohup $_epp_notifier >/dev/null  2>& 1 &
else
	echo -e "$_yellow_color To activate the client notifier on logged user please  $_white_color"
	echo -e "$_yellow_color open Dash and search for Endpoint Protector Notifier. $_white_color"
fi

echo

exit
