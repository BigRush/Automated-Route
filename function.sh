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
	DHCP_Network_configure
}

DHCP_Network_configure () {
	read -p "Do you want to configure the network? [Y,n]" DHCP_Network_configure_choise
	if [[ $DHCP_Network_configure_choise == "" ]] || [[ $DHCP_Network_configure_choise == "y" ]] || [[ $DHCP_Network_configure_choise == "Y" ]]; then
		Filter_Active_Interfaces
		Menu_Active_Interfaces "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
		Interface_Info
		User_Prompt
		Clone_Profile
		Activate_New_Profile
		echo " "
		echo $line
		echo $line
		DHCP_Info
	elif [[ $DHCP_Network_configure_choise == "n" ]] || [[ $DHCP_Network_configure_choise == "N" ]]; then
		echo " "
		echo $line
		echo $line
		DHCP_Info
	else
		echo "Invalid input, try again"
		DHCP_Network_configure
	fi
}
DHCP_Verify_Info_loop () {
  read -p "Is the information correct? [Y,n]" currect
  if [[ $currect == "" ]] || [[ $currect == "y" ]] || [[ $currect == "Y" ]]; then
    DHCP_Configuration
  elif [[ $currect == "n" ]] || [[ $currect == "N" ]]; then
    echo " "
    echo $line
    echo $line
    DHCP_User_Prompt
  else
    echo "Invalid input, try again"
    DHCP_Verify_Info_loop
  fi
}

DHCP_Verify_Info () {
  echo $line
  echo $line
  echo "Start of IP range : $New_Ip_Range_Start"
  echo " "
	echo "End of IP range : $New_Ip_Range_End"
  echo " "
	echo "Netmask : $New_Netmask"
  echo " "
	echo "Gateway: $New_Gateway"
  echo " "
  echo "Primary DNS : $New_DNS1"
  echo " "
  echo "Secondary DNS : $New_DNS2"
  echo " "
  echo " "
  DHCP_Verify_Info_loop
}

DHCP_Info () {
	Filter_Active_Interfaces
	if ! [[ -z $option ]];then
	  :
  else
	Menu_Active_Interfaces "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
  fi
	DHCP_User_Prompt
}

DHCP_User_Prompt () {
	Interface_Info
  # The next 2 lines are used later to validate ipv4 addresses
  oct='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
  ip4="^$oct\\.$oct\\.$oct\\.$oct$"
  # these set the default DNS, using google. yes Alex i love being spied on.
  DNS1="8.8.8.8"
  DNS2="8.8.4.4"
	Network_Base=$( echo $Ip | cut -d "." -f1,2,3 )
	Network=$( echo $Network_Base".0")
	Ip_Range_Start=$( echo $Network_Base".20" )
	Ip_Range_End=$( echo $Network_Base".200" )
  echo "Please enter the information to be set."
  echo "If a field is left blank, the current setting will be used"
  sleep 1
  echo " "
  read -p "Enter the start of IP range  [$Ip_Range_Start]: " New_Ip_Range_Start
  if [[ $New_Ip_Range_Start == "" ]]; then
    New_Ip_Range_Start=$Ip_Range_Start
  else
    until [[  $New_Ip_Range_Start == "" ]] || [[  "$New_Ip_Range_Start" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [$Ip_Range_Start]  : " New_Ip_Range_Start
    done
    if [[ $New_Ip_Range_Start == "" ]]; then
      New_Ip_Range_Start=$Ip_Range_Start
    fi
  fi
	echo $line
	read -p "Enter the end of IP range  [$Ip_Range_End]: " New_Ip_Range_End
  if [[ $New_Ip_Range_End == "" ]]; then
    New_Ip_Range_End=$Ip_Range_End
  else
    until [[  $New_Ip_Range_End == "" ]] || [[  "$New_Ip_Range_End" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [$Ip_Range_End]  : " New_Ip_Range_End
    done
    if [[ $New_Ip_Range_End == "" ]]; then
      New_Ip_Range_End=$Ip_Range_End
    fi
  fi
  echo $line
	read -p "Enter the netmask  [255.255.255.0]: " New_Netmask
  if [[ $New_Netmask == "" ]]; then
    New_Netmask="255.255.255.0"
  else
    until [[  $New_Netmask == "" ]] || [[  "$New_Netmask" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [255.255.255.0]  : " New_Netmask
    done
    if [[ $New_Netmask == "" ]]; then
      New_Netmask="255.255.255.0"
    fi
  fi
  echo $line
	read -p "Enter the gateway address [$Gateway]: " New_Gateway
  if [[ $New_Gateway == "" ]]; then
    New_Gateway=$Gateway
  else
    until [[  $New_Gateway == "" ]] || [[  "$New_Gateway" =~ $ip4 ]]; do
      read -p "Not a valid IP address. Re-enter [255.255.255.0]  : " New_Gateway
    done
    if [[ $New_Gateway == "" ]]; then
      New_Gateway=$Gateway
    fi
  fi
  echo $line
  read -p "Enter desired primary DNS for clients [$DNS1] : " New_DNS1
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
  read -p "Enter desired secondary DNS for clients [$DNS2] : " New_DNS2
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
  DHCP_Verify_Info
}


DHCP_Configuration () {
	printf "authoritative;\
	subnet $Network netmask $New_Netmask {/n
		range New_Ip_Range_Start New_Ip_Range_End;/n
		option domain-name-servers $New_DNS1, $New_DNS2;/n
		option routers $New_Gateway;/n
		option broadcast-address $Network_Base.255;/n
		default-lease-time 600;/n
		max-lease-time 7200;/n
	}"  > /etc/dhcp/dhcpd.conf.example
}


#DNS_Installation () {
#}

#DNS_Configuration () {

#}

DHCP_Installation
