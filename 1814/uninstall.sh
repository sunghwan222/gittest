#!/bin/bash
#
# uninstall.sh
#
# Created on: 30 July 2021
# Target: Linux debian distros machines
# Version: without dependencies
#
# Endpoint Protector offers Data Loss Prevention for Windows, Mac and Linux, as well as
# Mobile Device Management for Android and iOS.
#

readonly _epp_client_daemon=epp-client-daemon-d
readonly _epp_client_installed="$(dpkg -l | grep epp-client | awk '{print $3}' | head -1)"
readonly _option_ini_file="/opt/cososys/share/apps/epp-client/options.ini"
readonly _md5_set_entry="$(grep "protect=" ${_option_ini_file})"
readonly _md5_set_sum=${_md5_set_entry:8}
readonly _yellow_color="\e[1;33m"
readonly _white_color='\e[1;37m'
readonly _default="\033[1;00m"

echo -e "${_yellow_color}\nCredentials: ${_white_color}"
if [[ ${EUID} -ne 0 ]]; then
    echo -e "${_white_color}The $(basename ${BASH_SOURCE}) script is not running as root: NOK"
    exit
else
    echo -e "${_white_color}The current user is root: OK"
fi
if [[ "${_md5_set_sum}" != "0" ]] && [[ -n "${_md5_set_entry}" ]]; then
    read -s -p "Input uninstall password:" _password
    _md5_check_sum=$(printf '%s' "${_password}" | md5sum | awk '{print $1}')
    if [[ "${_md5_set_sum}" == "${_md5_check_sum}" ]]; then
        echo -e "${_white_color}" "\nThe uninstall password is correct.\n"
    else
        echo -e "${_white_color}" "\nThe uninstall password is not correct.\n"
        exit
    fi
else
    echo -e "${_white_color}The uninstall password is not requested.\n"
fi

echo -e "${_yellow_color}Begin the epp-client uninstalling with prerequisite. ${_white_color}"

echo -e "${_yellow_color}Check if the epp-client is already installed on this machine. ${_white_color}"
if [ "${_epp_client_installed}" != "" ]; then
    echo "The epp-client is installed. Proceeding with uninstalling."

    _epp_client_daemon_pid="$(ps faux | grep '/opt/cososys/sbin/epp-client-daemon' | grep -vw grep)"
    _epp_client_daemon_pid="$(echo "${_epp_client_daemon_pid}" | awk '{ print $2 }')"
    if [ -n "${_epp_client_daemon_pid}" ]; then
        echo "Send the uninstall event to the server."
        kill -s SIGUSR2 "${_epp_client_daemon_pid}"
        for _ts in {01..05}; do
            sleep 1
            printf "\rwait: %s s" "${_ts}"
        done
        echo
    fi

    echo "Stopping. ${_epp_client_daemon}"
    service ${_epp_client_daemon} stop
    echo "Uninstalling the epp-client."
    /usr/bin/crontab -l | grep -v '/opt/cososys/check-eppclient-process.sh' | /usr/bin/crontab -
    kill -s KILL "$(ps aux | grep [c]heck-eppclient-process.sh | awk '{print $2}')" 2>/dev/null
    kill -s KILL "$(ps aux | grep [e]pp-client | awk '{print $2}')" 2>/dev/null
    rm -rf /var/opt/cososys/epp-client
    rm -rf /var/log/epp-client
    dpkg --purge epp-client
    rm -rf /opt/cososys
    rm -rf /var/opt/cososys
    dpkg --purge epp-client-config
    dpkg --purge epp-client-cap-def
    dpkg --purge cososys-filesystem
    rm -rf /var/log/epp-client
    rm -f /etc/init.d/epp-client-daemon-d
    rm -f /etc/systemd/system/epp-client-daemon-d.service
    apt-key del D6D4A4CC

    echo -e "${_yellow_color}\nThe epp-client is successfully uninstalled.${_white_color}"
else
    echo -e "${_yellow_color}\nThe epp-client is not installed on this machine.${_white_color}"
fi

echo -e "${_default}"

exit
