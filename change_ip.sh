#!/bin/bash
#this is NOT meant to work with VIRTUAL interfaces, such as: eth0:1

set -x

#MAC="$1"
#NEW_IP="$2"
#NEW_NM="$3"
#NEW_GW="$4"
#INT_NOW="$5"
#FINDMAC="$6"
#INT_NOW="1"

function HELP(){
	
	echo ""
	echo "Usage of this script requires 5 variables to be fullfilled"
	echo "\t -a MAC"
	echo "\t -b New IP Address"
	echo "\t -c New NETMASK"
	echo "\t -d New GATEWAY"
	echo "\t -e Current interface count number of the system"
	
}

while getopts "a:b:c:e:d:" opt
do

echo "opt is: $opt"
echo "optarg is: $OPTARG"
	case "$opt" in
		a) MAC="$OPTARG";;
		b) NEW_IP="$OPTARG";;
		c) NEW_NM="$OPTARG";;
		e) INT_NOW="$OPTARG";;
#		?) HELP ;;
		d) 

			if [[ "$OPTARG" == "none" ]]; then
				NEW_GW=""
			else
				NEW_GW="$OPTARG"
			fi

		;;

	esac
done

#if [ -z "$MAC" ]; then
#	echo "Enter in the interface you want to re-ip: "
#	read MAC < /dev/tty
#fi

#if [ -z "$NEW_IP" ]; then
#	echo "Enter in the new IP you want: "
#	read NEW_IP < /dev/tty
#fi

#if [ -z "$NEW_NM" ]; then
#	echo "Enter in the Netmask: "
#	read NEW_NM < /dev/tty
#fi

#if [ -z "$NEW_GW" ]; then
#	echo "Enter in the Gateway: "
#	read NEW_GW < /dev/tty
#fi

#if [ -z "$INT_NUM" ]; then
#	echo "How many Network Interfaces does this machine have?"
#	read INT_NUM < /dev/tty
#fi

function IP_REDHAT() {
	
	BACKUP_REDHAT
	
	echo "finding interface name: "
	
	FIND_INT_NAME_RED
	
	BUILD_IFCFG
	
	BUILD_ROUTE
	
	IF_RESET
	
}

function IP_DEBIAN() {
	
#plan: figure out interfaces to modify, then modify one by one.
#doing MAC stuff outside of VM, at powercli/shell vmware level.	
#	CHECK_MAC	

	BACKUP_DEB
	
#This was a loop but not anymore. Running script multiple times from PowerCLI to pass proper MAC's
##not using MAC's anymore anyways. yeeesh.
	echo "finding interface name: "
	
	FIND_INT_NAME_DEB

	BUILD_INTERFACES

	IF_RESET

	echo "done"

}

#Not used right now/anymore
function CHANGE_DEB_IP() {

#need to get number of interfaces and make a variable and loop for such

# Change MAC Address
	sed -i -e "s/\<hwaddress ether\>/hwaddress ether $INTERFACE/$INT_NOW" /etc/network/interfaces

# Change IP Address
	sed -i -e "s/\<address\>/address $NEW_IP/$INT_NOW" /etc/network/interfaces

# Change netmask
	sed -i -e "s/\<netmask\>/netmask $NEW_NM/$INT_NOW" /etc/network/interfaces

# Change Gateway
	sed -i -e "s/\<gateway\>/gateway $NEW_GW/$INT_NOW" /etc/network/interfaces

	echo "ran DEB IP"

}

function BACKUP_REDHAT() {

	NOW=$(date +%Y-%m-%d)
	
	if [ -f "/var/network-backup-$NOW/" ]; then
		echo "A backup was already made earlier today"
	else
		mkdir -p /var/network-backup-$NOW/; cp -n /etc/sysconfig/network-scripts/ifcfg-* /var/network-backup-$NOW/
		echo "backup ran"
	fi
	
}

function BACKUP_DEB() {
	
	NOW=$(date +%Y-%m-%d)
	
	if [ -f "/var/network-backup/"$NOW".interfaces.backup" ]; then
		echo "A backup was already made earlier today"
	else
		mkdir -p /var/network-backup/; cp -n /etc/network/interfaces /var/network-backup/$NOW.interfaces.backup
		echo "backup ran"
	fi	
	
}

function IF_RESET() {
#Need to --force, will throw an error saying it cannot bring Interface back up, but ifconfig shows proper IP

	ifdown $INT_NAME -v --force

	ifup $INT_NAME -v --force

}

function FIND_INT_NAME_DEB() {

	#old way to find interface list
	#INT_NAME=$(ifconfig | expand | cut -c 1-8 | sort | uniq -u | awk -F: "NR==$INT_NOW{print $1;}")

	INT_NAME=$(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d' | sort | uniq -u | awk "NR==$INT_NOW{print $1;}")

	echo "int name variable is: " $INT_NAME

}

function FIND_INT_NAME_RED() {
	
	#need to find a way to do all/both OS's without separate functions
	#INT_NAME=$(ifconfig -a | sed 's/[ \t].*//;/^\(lo:\|\)$/d' | sort | uniq -u | awk "NR==$INT_NOW{print $1;}")
	INT_NAME=$(ip -o link show | grep -Fv -e lo -e virb | sort | awk -F': ' "NR=="$INT_NOW"{print \$2}")
	echo "int name variable is: " $INT_NAME
	
}

function BUILD_INTERFACES() {
#sticking with gateway in the interfaces file than vs trying to do static routes. It's painful in debian.
	
	echo "#" >> /etc/network/interfaces; sed -i '1 c #This file was re-built by a script' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '2 c #' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '3 c #' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '4 c #The loopback interface' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '5 c auto lo' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '6 c iface lo inet loopback' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '7 c #' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '8 c #' /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i '9 c #' /etc/network/interfaces
	
	#everything after this needs to be loopable for numbers of interfaces to be configured
	
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"0 c auto "$INT_NAME"" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"1 c allow-hotplug "$INT_NAME"" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"2 c iface "$INT_NAME" inet static" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"3 c #Useless for now hwaddress ether "$MAC"" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"4 c address "$NEW_IP"" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"5 c netmask "$NEW_NM"" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"6 c gateway "$NEW_GW"" /etc/network/interfaces
	#can add static routes maybe...
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"7 c #" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"8 c #" /etc/network/interfaces
	echo "#" >> /etc/network/interfaces; sed -i ""$INT_NOW"9 c #" /etc/network/interfaces
	#delete lines that are extra/erroneous/left-over
	sed -i ""$(($INT_NOW+1))"0, $ d" /etc/network/interfaces
	
	echo "I changed a line in interfaces file i think"
	
}

function BUILD_IFCFG() {
	
	#check to see if file exists, make if needed. Then we will modify/build it
	
	if [ ! -f "/etc/sysconfig/network-scripts/ifcfg-"$INT_NAME"" ]; then 
		
		touch /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "made ifcfg file"
	fi
		
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "1 c #This file was built by a script" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "2 c DEVICE="$INT_NAME"" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "3 c #Useless for now HWADDR="$MAC"" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "4 c BOOTPROTO=static" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "5 c ONBOOT=yes" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "6 c IPADDR="$NEW_IP"" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "7 c NETMASK="$NEW_NM"" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "8 c #GATEWAY="$NEW_GW"" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "9 c MTU=1500" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "#" >> /etc/sysconfig/network-scripts/ifcfg-$INT_NAME; sed -i "10 c NM_CONTROLLED=no" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		sed -i "11, $ d" /etc/sysconfig/network-scripts/ifcfg-$INT_NAME
		echo "built the ifcfg file"
	
}

function BUILD_ROUTE() {
	#this build the route files for Redhat based OS's. To do such for debian is not easy so we just stick with the gateway listing for debian.
	if [ ! -f "/etc/sysconfig/network-scripts/route-"$INT_NAME"" ]; then 
	
		touch /etc/sysconfig/network-scripts/route-$INT_NAME
		echo "made route file"
	fi
	
	echo "#" >> /etc/sysconfig/network-scripts/route-$INT_NAME; sed -i "1 c #This file was built by a script" /etc/sysconfig/network-scripts/route-$INT_NAME
	echo "#" >> /etc/sysconfig/network-scripts/route-$INT_NAME; sed -i "2 c default via "$NEW_GW" dev "$INT_NAME"" /etc/sysconfig/network-scripts/route-$INT_NAME
	
	#leave room for padding and other manual static routes?
	sed -i "11, $ d" /etc/sysconfig/network-scripts/route-$INT_NAME
	echo "built a route file"
	
}

#check to see if it a derivative of ubuntu OS
if [ -f "/etc/network/interfaces" ]; then
	echo "This is some form of Debian based OS"
	#run function for Debian based OS changes
	IP_DEBIAN
elif [ -f "/etc/sysconfig/network-scripts/" ]; then

	echo "This is some form of Redhat based OS"
	IP_REDHAT

elif [ -f "/etc/sysconfig/network/" ]; then

	echo "This is some form of SUSE"
	IP_SUSE

else

	echo "Not a compatible OS"

fi







