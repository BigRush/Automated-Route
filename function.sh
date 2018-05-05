#!/usr/bin/env bash

#######################################################################################
# Authors	: chn555 & BigRush
#
#License	: GPLv3
#
# Description	: DNS & DHCP server installation and configuration
#
# Version	: 1.0.0
#######################################################################################


####Functions####


Log_And_Variables () {
	dns_install_log=/var/log/Automated-Route/dns_install.log
	dns_service_log=/var/log/Automated-Route/dns_service.log
	dhcp_install_log=/var/log/Automated-Route/dhcp_install.log
	dhcp_service_log=/var/log/Automated-Route/dhcp_servicel.log


	if [[ -d /var/log/Automated-Route ]]; then
		:
	else
		mkdir -p /var/log/Automated-Route
	fi

}

source NAMfunctions.sh



Root_Check () {		## checks that the script runs as root
	if [[ $EUID -eq 0 ]]; then
		:
	else
		printf "$line\n"
		printf "The script needs to run with root privileges\n"
		printf "$line\n"
		exit 1
	fi
}

Distro_Check () {		## checking the environment the user is currenttly running on to determine which settings should be applied
	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^arch$|^manjaro$" &> /dev/null

	if [[ $? -eq 0 ]]; then
	  	Distro_Val="arch"
	else
	  	:
	fi

  cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^debian$|^\"Ubuntu\"$" &> /dev/null

  if [[ $? -eq 0 ]]; then
    	Distro_Val="debian"
  else
    	:
  fi

	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^\"centos\"$|^\"fedora\"$" &> /dev/null

	if [[ $? -eq 0 ]]; then
	   	Distro_Val="centos"
	else
		:
	fi
}

DHCP_Installtion () {		## install dhcp
	yum install -y bind bind-utils -y
}


DHCP_Configuration () {

}


DNS_Installation () {

}

DNS_Configuration () {

}
