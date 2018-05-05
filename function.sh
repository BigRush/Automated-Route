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

<<<<<<< HEAD

Log_And_Variables () {
	dns_install_log=/var/log/Automated-Route/dns_install.log
	dns_service_log=/var/log/Automated-Route/dns_service.log
	dhcp_install_log=/var/log/Automated-Route/dhcp_install.log
	dhcp_service_log=/var/log/Automated-Route/dhcp_servicel.log
	dns_conf=/etc/named.conf

	if [[ -d /var/log/Automated-Route ]]; then
		:
	else
		mkdir -p /var/log/Automated-Route
	fi

}

=======
>>>>>>> a10df73ab25811b20ac91bc5af8d5f554c77022c
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

<<<<<<< HEAD
DHCP_Installtion () {		## install dhcp
=======
DHCP_Installation () {
	echo "Now installing DHCP service"
	yum install dhcp -y && echo "DHCP installed"


>>>>>>> a10df73ab25811b20ac91bc5af8d5f554c77022c

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
	yum install -y bind bind-utils -y &> $dns_install_log		## install dns bind-utils
	if [[ $? -eq 0 ]]; then		## checks exit status to see if the installation was successfull
		sed -ie 's/listen-on port 53.*/listen-on port 53 { any; };/' $dns_conf &> $dns_service_log



}

DNS_Configuration () {

}
