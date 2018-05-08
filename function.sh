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


echo $line

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

	if ! [[ $Distro_Val == "centos" ]]; then
		printf "Sorry, this script does not support your system"
	fi
}

Log_And_Variables () {
	source NAMfunctions.sh

	line=$(printf '%40s\n' | tr ' ' -)
	dns_install_log=/var/log/Automated-Route/dns_install.log
	dns_service_log=/var/log/Automated-Route/dns_service.log
	log_path=/var/log/Automated-Route
	dns_conf=/etc/named.conf

	zone_path=/var/named


	## checks if the net ID ends with 0 or its a subnetted network for the input
	if [[ $(printf "$NetID\n" |cut -d '.' -f 4 |cut -c 1) -eq 0 ]]; then
		input=$(printf "$NetID\n" |cut -d '.' -f 1,2,3)
	else
		input=$(printf "$NetID\n" |cut -d '.' -f 1,2,3,4 |cut -d '/' -f 1)
	fi

	reverse_NetID=' '		## this weill be our revresed net ID

	## loop for reversing the net ID
	for   (( i=0; i<${#input}; i++ )); do
    	reverse_NetID="${input:${i}:1}$reverse_NetID"
	done


	if ! [[ -d $log_path ]]; then
		mkdir -p $log_path
	fi


}

DNS_Installation () {
	printf "Installing DNS bind\n"
	yum -y install bind bind-utils &>> $dns_install_log
	if [[ $? -eq 0 ]]; then

		DNS_Configuration
	else
		printf "Something went wrong during installation\nPlease check log file under:\n$dns_install_log\n"
	fi

}


IP_Check () {
	int_menu=($(nmcli connection show |awk '{print $4}'|sed '1d') Quit)
	echo ${#int_menu[@]}
	echo ${int_menu[@]}
	int_number=$(expr ${#int_menu[@]} - 1)
	echo ${int_menu[@]:0:$int_number}
	local PS3="Please choose your an interface to be set on the DNS: "
	select opt in ${int_menu[*]}; do
	case $opt in
	        ${int_menu[@]:0:$int_number})
	                                ip_addr=$(nmcli dev show $opt |awk '/IP4.ADDRESS/{print $2}')
	                                echo $ip_addr
	                                ;;
	                                Quit)
	                                printf "Exit - Have a nice day!\n"
	                                exit 0
	                                ;;
	                                *)
	                                printf "Invalid option\n"
	                                ;;


	esac
	done

}

DNS_Configuration () {
	printf "Creating dns configuration back up file...\n"
	cat $dns_conf > $dns_conf.bck		## Creating dns configuration back up file

	read -p "Please enter the domain name to be entered in the DNS configuring: " Domain

	# If NAM ran before, dont filter interfaces, prevents duplicates
	if ! [[ -z $option ]];then
		:
	else
		Filter_Active_Interfaces
	fi

	Menu_Active_Interfaces "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"
	Interface_Info

	sed -ie 's/listen-on port 53.*/listen-on port 53 { any; };/' $dns_conf &>> $dns_service_log
	sed -ie 's/listen-on-v6 port 53.*/listen-on-v6 { none; };/' $dns_conf &>> $dns_service_log
	sed -ie "s/allow-query.*allow-query         { localhost; $NetID; };/" $dns_conf &>> $dns_service_log
	printf "
	zone \"$Domain\" IN {
		type master;
		file \"$Domain.f.zone\";
		allow-update { none; };
		};
		zone \"$reverse_NetID.in-addr.arpa\" IN {
		type master;
		file \"$Domain.r.zone\";
		allow-update { none; };
		};
	" >> $dns_conf




	printf "
$TTL 86400
@	IN	SOA		$Domain.	root.$Domain. (
		2011071001  ;Serial
		3600        ;Refresh
		1800        ;Retry
		604800      ;Expire
		86400       ;Minimum TTL
)
@       IN  NS          $Domain.
@       IN  A           $Ip

dns0	IN	A	$Ip
	" > $zone_path/$Domain.f.zone

	printf "
$TTL 86400
@	IN	SOA		dns0.gruh.local.	root.gruh.local. (
2011071001  ;Serial
3600        ;Refresh
1800        ;Retry
604800      ;Expire
86400       ;Minimum TTL
)
			 IN  NS          dns0.gruh.local.
			 IN  A           $Ip

dns0		IN		A		$Ip
	"	> $zone_path/$Domain.f.zone

	systemctl enable named &>> $dns_service_log
	if [[ $? -ne 0 ]]; then
		printf "Something went wrong while enabling the service.\nPlease check log under:\n$dns_service_log\n"
		exit 1
	fi

	systemctl restart named &>> $dns_service_log
	if [[ $? -eq 0 ]]; then
		printf "DNS service is up and running!\n"
		Main_Menu
	else
		printf "Something went wrong while restarting the service.\nPlease check log under:\n$dns_service_log\n"
		exit 1
	fi

}

DHCP_Installation () {
	echo "Now installing DHCP service"
	yum install dhcp -y && echo $line && echo "DHCP installed, moving on.."
	echo " "
	echo $line
	DHCP_Network_configure
}

# Asks the user if they would like to configure the network. using NAM.
DHCP_Network_configure () {
	read -p "Do you want to configure the network? [Y,n]" DHCP_Network_configure_choise
	echo " "
	echo $line
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

# Asks the user if the details are correct, if they are move on, if not the run the user prompt again
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

# Display the info entered, then starts the verify info loop.
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

# Gathers info about network interfaces and IP
DHCP_Info () {
	# If NAM ran before, dont filter interfaces, prevents duplicates
	if ! [[ -z $option ]];then
	  :
  else
		Filter_Active_Interfaces

  fi
	Menu_Active_Interfaces "${#Filtered_Active_Interfaces[@]}" "${Filtered_Active_Interfaces[@]}"

	DHCP_User_Prompt
}

# Prompt user for the neccesserry info
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

# Export the dhcpd templete using the info gathered.
DHCP_Configuration () {
	printf "
	authoritative;
	subnet $Network netmask $New_Netmask {
		range $New_Ip_Range_Start $New_Ip_Range_End;
		option domain-name-servers $New_DNS1, $New_DNS2;
		option routers $New_Gateway;
		option broadcast-address $Network_Base.255;
		default-lease-time 600;
		max-lease-time 7200;
	}"  > /etc/dhcp/dhcpd.conf

	echo "DHCP configured, starting..."
	systemctl enable dhcpd
	systemctl start dhcpd && echo "DHCP running" || $( echo "DHCP failed, check the logs" && exit 1 )
}


Main_Menu () {
	Log_And_Variables
	Root_Check
	Distro_Check


	local PS3="Please choose the service you would like to install: "

	Menu=(DHCP DNS)
	select opt in ${Menu[@]}; do
		case $opt in
			DHCP)
				DHCP_Installation
				;;

			DNS)
				DNS_Installation
				;;

			*)
				printf "Invalid option, please try again\n"
		esac
	done
}
Main_Menu
