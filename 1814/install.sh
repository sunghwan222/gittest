#!/bin/bash
#
# install.sh
#
# Created on: 21 Feb 2020
# Target: Linux debian distros machines
# Version: without dependencies (THIN)
#
# Endpoint Protector offers Data Loss Prevention for Windows, Mac and Linux,
# as well as Mobile Device Management for Android and iOS.
#

## Define variables used by install.sh script

readonly _use_dpkg_tool="yes"

readonly _distro_id="$(awk '/DISTRIB_ID=/' /etc/*-release | sed 's/DISTRIB_ID=//' | tr '[:upper:]' '[:lower:]')"
readonly _distro_version="$(awk '/DISTRIB_RELEASE=/' /etc/*-release | sed 's/DISTRIB_RELEASE=//' | sed 's/[.]0/./')"
readonly _arch="$(/bin/uname -m)"
readonly _path_build="$(dirname $0)"
readonly _epp_client_daemon="epp-client-daemon-d"
readonly _dependencies_path="${_path_build}/deps"
readonly _packages_path="${_path_build}/pkgs"
readonly _configuration_path="/opt/cososys/share/apps/epp-client"
readonly _configuration_file="options.ini"
readonly _check_eppclient_process_sh="/opt/cososys/check-eppclient-process.sh"
readonly _epp_client_status="$(dpkg -l | grep 'epp-client' | awk '{print $1}' | head -1)"
readonly _epp_client_cap_def_status="$(dpkg -l | grep 'epp-client-cap-def' | awk '{print $1}' | head -1)"
readonly _epp_client_config_status="$(dpkg -l | grep 'epp-client-config' | awk '{print $1}' | head -1)"
readonly _cososys_filesystem_status="$(dpkg -l | grep 'cososys-filesystem' | awk '{print $1}' | head -1)"
readonly _current_user="$(whoami)"
readonly _epp_notifier="/opt/cososys/bin/epp-client"
readonly _epp_client_file="/opt/cososys/bin/epp-client"
readonly _epp_client_png_file="/usr/share/pixmaps/epp-client.png"

readonly _yellow_color="\e[1;33m"
readonly _red_color='\e[1;31m'
readonly _white_color='\e[1;37m'
readonly _default="\033[1;00m"

echo
echo -e "${_white_color}The current user is ${_current_user}"

## Check if epp-client is installed
echo -e "${_yellow_color}\nCheck if the epp-client is already installed. ${_white_color}"

if [ "${_epp_client_status}" == 'ii' ] && [ "${_epp_client_cap_def_status}" == 'ii' ] &&
    [ "${_epp_client_config_status}" == 'ii' ] && [ "${_cososys_filesystem_status}" == 'ii' ]; then

    echo -e "${_white_color}The epp-client is installed. Updating options.ini"
    echo -e "${_white_color}Stopping ${_epp_client_daemon}"
    service ${_epp_client_daemon} stop
    echo -e "${_white_color}Changing ${_configuration_path}/${_configuration_file} with content:"
    cat ${_path_build}/${_configuration_file}
    chmod 777 ${_configuration_path}/${_configuration_file}
    cat "${_path_build}"/${_configuration_file} >${_configuration_path}/${_configuration_file}
    echo -e "${_white_color}Starting ${_epp_client_daemon}"
    service ${_epp_client_daemon} start >/dev/null 2>&1 &
    exit
else
    echo -e "${_white_color}The epp-client is not installed on this machine."
fi

## Begin to install dependencies
echo -e "${_yellow_color}\nBegin to install dependencies. ${_white_color}"
_list_dependencies=""
for _entry_list_dependencies in $(ls $_dependencies_path); do
    _program_package=$(echo "$_entry_list_dependencies" | sed 's/_[0-9].*//')
    sudo dpkg -s "${_program_package}" &>/dev/null

    if [ $? -eq 0 ]; then
        echo -e "${_white_color}Package ${_program_package} is already installed."
    else
        echo -e "${_white_color}Package ${_program_package} will be installed."
        _new_list_dependencies="${_list_dependencies} ${_dependencies_path}/${_entry_list_dependencies}"
        _list_dependencies=${_new_list_dependencies}
    fi
done
if [ "${_list_dependencies}" == "" ]; then
    echo -e "${_white_color}All dependencies are already installed."
    _dpkg_error=0
else
    echo -e "${_white_color}paths = ${_list_dependencies}"
    dpkg --force-depends -i "${_list_dependencies}"
    _dpkg_error=$?
fi

if [ ${_dpkg_error} -ne 0 ]; then
    echo -e "${_red_color}Error: installing epp packages. Exiting... ${_white_color}"
    exit ${_dpkg_error}
fi

## Begin to install packages for epp-client
echo
if [ "${_arch}" == "x86_64" ]; then
    echo -e "${_yellow_color}Installing x86_64 (64b) packages. ${_white_color}"
else
    echo -e "${_yellow_color}Installing i386 (32b) packages. ${_white_color}"
fi

## The epp-client public key is added
echo -e "${_white_color}The epp-client public key is added."
apt-key add "${_path_build}"/cososys_gpg2_public.key

_failed=0
dpkg -i "${_packages_path}"/cososys-filesystem_*.deb || _failed=1
dpkg -i "${_packages_path}"/epp-client-cap-def_*.deb || _failed=1
dpkg -i "${_packages_path}"/epp-client-config_*.deb || _failed=1

## Exit with error if any of the above failed
if [ "${_failed}" -ne 0 ]; then
    echo -e "${_red_color}Error installing epp packages. Exiting... ${_white_color}"
    exit
fi

echo -e "${_white_color}Changing config file to match IP/PORT/Department with provided values."
echo -e "${_white_color}${_path_build}/${_configuration_file}"
cp ${_path_build}/${_configuration_file} ${_configuration_path}/${_configuration_file}

if [[ ${_use_dpkg_tool} == "yes" ]]; then
    # gdebi crashes when trying to install packages
    # this is a bug for some Linux distros
    dpkg -i ${_packages_path}/epp-client_*.deb 2>/dev/null
    apt-get -f install
else
    # gdebi installs .deb packages with automatic depenencies
    apt install -y gdebi
    gdebi -n "${_packages_path}"/epp-client_*.deb 2>/dev/null
fi

_exit_code=$?
if [ ${_exit_code} -ne 0 ]; then
    echo -e "${_red_color}Error: installing epp packages. Exiting... ${_white_color}"
    exit ${_exit_code}
fi

cp "${_path_build}"/check-eppclient-process.sh ${_check_eppclient_process_sh}

## Config and restart crotab
echo
echo -e "${_yellow_color}Configure and restart crontab job scheduler.${_white_color}"
chmod 700 ${_check_eppclient_process_sh}
(/usr/bin/crontab -l | grep ${_check_eppclient_process_sh}) ||
    (
        /usr/bin/crontab -l
        /bin/echo "* * * * * ${_check_eppclient_process_sh} &> /dev/null 2>&1"
    ) |
    /usr/bin/crontab -u root -

# Reload systemd manager configuration
systemctl daemon-reload

# Start epp-client-daemon at boot phase
systemctl enable epp-client-daemon-d

# Reload crond configuration
if [ "${_distro_id}" == "ubuntu" ]; then
    [ "${_distro_version}" == "16.04" ] && systemctl reload cron
    [ "${_distro_version}" == "18.04" ] && systemctl reload cron
    [ "${_distro_version}" == "20.04" ] && systemctl reload crond
fi

# Restart epp-client-daemon-d service
systemctl restart epp-client-daemon-d

echo
if [ "$1" == "--cli" ]; then
    rm ${_epp_client_file} >/dev/null 2>&1 &
    rm ${_epp_client_png_file} >/dev/null 2>&1 &
    echo -e "${_white_color}The epp-client without GUI was successfully installed.\n ${_white_color}"
    exit
fi

echo -e "${_yellow_color}The epp-client with GUI was successfully installed. ${_white_color}"

## If the user is not root then the epp-client notifier is launched
echo
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${_yellow_color}Activate the client notifier that can be accessed from system tray.  ${_white_color}"
    # put the epp-client notifier to run in backgroud and make the shell not wait for completion
    nohup ${_epp_notifier} >/dev/null 2>&1 &
else
    echo -e "${_yellow_color}To activate the client notifier on logged user please  ${_white_color}"
    echo -e "${_yellow_color}open Dash and search for Endpoint Protector Notifier. ${_white_color}"
fi

echo -e "${_default}"

exit
