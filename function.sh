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

DHCP_Installation () {
	echo "Now installing DHCP service"
	yum install dhcp -y && echo "DHCP installed"



}


DHCP_Configuration () {

	"authoritative;

	subnet 192.168.15.0 netmask 255.255.255.0 {
		range 192.168.15.20 192.168.15.254;
		option domain-name-servers 8.8.8.8, 8.8.4.4;
		option routers 192.168.15.1;
		option broadcast-address 192.168.15.255;
		default-lease-time 600;
		max-lease-time 7200;
	}"

}


DNS_Installation () {

}

DNS_Configuration () {

}
