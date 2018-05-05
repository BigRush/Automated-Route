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
	dns_conf=/etc/named.conf

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

DHCP_Installation () {
	echo "Now installing DHCP service"
	yum install dhcp -y && echo "DHCP installed"


}

DHCP_User_Prompt () {
  # The next 2 lines are used later to validate ipv4 addresses
  oct='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
  ip4="^$oct\\.$oct\\.$oct\\.$oct$"
  # these set the default DNS, using google. yes Alex i love being spied on.
  DNS1="8.8.8.8"
  DNS2="8.8.4.4"
	Network=$( echo $New_Ip | cut -d "." -f-1,2,3-s )
  echo "Please enter the information to be set."
  echo "If a field is left blank, the current setting will be used"
  sleep 1
  echo " "
  read -p "Enter the start of IP range  : " New_Ip_Range_Start
  if [[ $New_Ip == "" ]]; then
    New_Ip=$Ip
  else
    until [[  $New_Ip == "" ]] || [[  "$New_Ip" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [$Ip]  : " New_Ip
    done
    if [[ $New_Ip == "" ]]; then
      New_Ip=$Ip
    fi
  fi
	read -p "Enter desired IP address [$Ip] : " New_Ip
  if [[ $New_Ip == "" ]]; then
    New_Ip=$Ip
  else
    until [[  $New_Ip == "" ]] || [[  "$New_Ip" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [$Ip]  : " New_Ip
    done
    if [[ $New_Ip == "" ]]; then
      New_Ip=$Ip
    fi
  fi
  echo $line
  read -p "Enter desired primary DNS [$DNS1] : " New_DNS1
  if [[ $New_DNS1 == "" ]]; then
    New_DNS1=$DNS1
  else
    while [[ ! $New_DNS1 == "" ]] && [[ ! "$New_DNS1" =~ $ip4 ]]; do
      read -p "Not a valid DNS. Re-enter [$DNS1] :  " New_DNS1
    done
    if [[ $New_DNS1 == "" ]]; then
      New_DNS1=$DNS1
    fi
  fi
  echo $line
  read -p "Enter desired secondary DNS [$DNS2] : " New_DNS2
  if [[ $New_DNS2 == "" ]]; then
    New_DNS2=$DNS2
  else
    while [[ ! $New_DNS2 == "" ]] && [[ ! "$New_DNS2" =~ $ip4 ]]; do
      read -p "Not a valid DNS. Re-enter [$DNS2] :  " New_DNS1
    done
    if [[ $New_DNS2 == "" ]]; then
      New_DNS1=$DNS2
    fi
  fi
  Verify_Info
}
DHCP_Configuration () {

	printf "authoritative;\
\
	subnet 192.168.15.0 netmask 255.255.255.0 {\
		range 192.168.15.20 192.168.15.254;\
		option domain-name-servers 8.8.8.8, 8.8.4.4;\
		option routers 192.168.15.1;\
		option broadcast-address 192.168.15.255;\
		default-lease-time 600;\
		max-lease-time 7200;\
	}"  > /etc/dhcp/dhcpd.conf

}


DNS_Installation () {
	yum install -y bind bind-utils -y &> $dns_install_log		## install dns bind-utils
	if [[ $? -eq 0 ]]; then		## checks exit status to see if the installation was successfull
		sed -ie 's/listen-on port 53.*/listen-on port 53 { any; };/' $dns_conf &> $dns_service_log



}

DNS_Configuration () {

}
