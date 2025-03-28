#!/bin/bash
# ----------------------------------------------------------------------#
# [Author]       Nixxis Support Team/Nixxis Indian Ocean                #
# [Company]      Nixxis Belgium S.P.R.L.                                #
# [Title]        Nixxis Media Server Installation Script                #
# [Description]  This script is a tool which allow installation and     #
#                maintenance in a super easy way. Installation become   #
#                as simple as typing the name of the script followed    #
#                by a command and then look back when the job is done   #
# ----------------------------------------------------------------------#
# [Prerequisities]  Must be run as root on Rocky Linux 9                     #
# [Usage]           * Give execution right to the script                #
#                   * Run the script with action as argument            #
#                       - Install will install Nixxis MS                #
#                       - Config is a wizard to config sip connection   #
#                       - Check components health                       #
# ----------------------------------------------------------------------#
# [File Version]        3.1                                           #
# [Nixxis Version]      3.1                                           #
# [Asterisk Version]    20                                           #
# ----------------------------------------------------------------------#
# [Last Update]         2 Jully 2024							            #
#                       Updated to Nixxis Contact Suite 3.1           #
#                       							                    #
# ----------------------------------------------------------------------#


# Define text color
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
ORANGE=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
NORMAL=$(tput sgr0)
# Usefull variables
ScriptDir=`cd "$(dirname "$0")" && pwd`
col=55
col3=$((columns / 3))
col2=$((columns / 2))
failcount=0
isrestartneeded="false"
doconfig="true"
installhardware="false"
# Parameters
appsound="S0unds"
pbxsound="S0unds"
pbxrecor="Rec0rding"
osversion="0"
osuname=`uname -r`
osarch="32"
#To be updated at each release
NixxisUri="http://update.nixxis.net/v3.1/Install.3.1.2.zip"
Asterisk="https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-20.9.0.tar.gz"
AsteriskVersionComp="asterisk-20.9.0.tar.gz"
AsteriskVersion="asterisk-20.9.0"
packages=(
    "gcc"
    "gcc-c++"
    "chkconfig"
    "jq"
    "dos2unix"
	"libcurl"
    "curl"
    "curl-devel"
    "jwhois"
    "chrony"
    "nano"
    "kernel-devel"
    "bison"
    "jq"
    "xmlstarlet"
    "tmpwatch"
    "ckermit"
    "sox"
    "lighttpd"
    "wireshark"
    "wget"
    "mlocate"
    "rsync"
    "svn"
    "mpg123"
    "lame-devel"
    "php-cli"
	"cockpit"
)

echo -ne "\n\n"
echo "  /\\\\\\\\\\     /\\\\\\       $(tput setaf 2)                            $(tput sgr0)                           $(tput dim)                                                            "
echo "  \\/\\\\\\\\\\\\   \\/\\\\\\       $(tput setaf 2)                            $(tput sgr0)                          $(tput dim)                                                            "
echo "   \\/\\\\\\/\\\\\\  \\/\\\\\\  /\\\\\\ $(tput setaf 2)                            $(tput sgr0) /\\\\\\                    $(tput dim)                                                            "
echo "    \\/\\\\\\//\\\\\\ \\/\\\\\\ \\///  $(tput setaf 2) /\\\\\\    /\\\\\\  /\\\\\\    /\\\\\\ $(tput sgr0)\\///   /\\\\\\\\\\\\\\\\\\\\      $(tput dim)  __  __          _ _        _____                          "
echo "     \\/\\\\\\\\//\\\\\\\\/\\\\\\  /\\\\\\ $(tput setaf 2)\\///\\\\\\/\\\\\\/  \\///\\\\\\/\\\\\\/  $(tput sgr0) /\\\\\\ \\/\\\\\\//////      $(tput dim) |  \/  |        | (_)      / ____|                         "
echo "      \\/\\\\\\ \\//\\\\\\/\\\\\\ \\/\\\\\\ $(tput setaf 2)  \\///\\\\\\/      \\///\\\\\\/    $(tput sgr0)\\/\\\\\\ \\/\\\\\\\\\\\\\\\\\\\\    $(tput dim) | \\  / | ___  __| |_  __ _| (___   ___ _ ____   _____ _ __ "
echo "       \\/\\\\\\  \\//\\\\\\\\\\\\ \\/\\\\\\ $(tput setaf 2)   /\\\\\\/\\\\\\      /\\\\\\/\\\\\\   $(tput sgr0)\\/\\\\\\ \\////////\\\\\\   $(tput dim) | |\\/| |/ _ \\/ _  | |/ _  |\\___ \\ / _ \\  __\\ \\ / / _ \\  __|"
echo "        \\/\\\\\\   \\//\\\\\\\\\\ \\/\\\\\\ $(tput setaf 2) /\\\\\\/\\///\\\\\\  /\\\\\\/\\///\\\\\\ $(tput sgr0)\\/\\\\\\  /\\\\\\\\\\\\\\\\\\\\  $(tput dim) | |  | |  __/ (_| | | (_| |____) |  __/ |   \\ V /  __/ |   "
echo "         \\///     \\/////  \\///  $(tput setaf 2)\\///    \\///  \\///    \\///  $(tput sgr0)\\///  \\//////////  $(tput dim) |_|  |_|\\___|\\__,_|_|\\__,_|_____/ \\___|_|    \\_/ \\___|_|   "
echo -ne "\n\n"
export LANG=en_GB.UTF-8
float_scale=3
function float_eval()
{
    local stat=0
    local result=0.0
    if [[ $# -gt 0 ]]; then
        result=$(echo "scale=$float_scale; $*" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}
nms_install(){
	mkdir -p /var/log/nixxis/
	mv /var/log/nixxis/installation.log /var/log/nixxis/installation.log.old 2> /dev/null
# Check if user is root.
	if [ "$UID" -ne "0" ] ; then
		printf '\n\n %-25s %s\n ' " " "$RED You must run this script as root $NORMAL"
		printf '\n\n %-25s %s\n ' " " "$RED You must run this script as root $NORMAL" >> /var/log/nixxis/installation.log
		exit
	else
		echo "executing as root" >> /var/log/nixxis/installation.log
	fi
	
# Check if os is supported Rocky Linux.
	if rpm -qa \*-release | grep -Ei "Rocky" | cut -d"-" -f3 | grep -iho "9" > /dev/null 2>&1; then
                        osversion="9"
                        if uname -m | grep -q "x86_64" > /dev/null 2>&1; then
                                osarch="64"
                                echo "Rocky Linux 9 64bit Installed" >> /var/log/nixxis/installation.log
                        else
                                echo "Rocky Linux 9 32bit Installed" >> /var/log/nixxis/installation.log
                        fi

        else
                        printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "This installation of Nixxis is for Rocky Linux 9 only"
                        printf '\n\n %-25s %s\n ' " " "$RED This installation of Nixxis is for Rocky Linux 9 only $NORMAL" >> /var/log/nixxis/installation.log
                        exit
        fi
	printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "OS Rocky Linux $osversion installed"
	
	
	if [ -d /etc/asterisk ] ; then
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Backing up old Nixxis File" "#####$NORMAL"
		#Copying files
		printf '%-*s %s\r ' $col "Copying files" "$NORMAL [ ... ] $NORMAL"
		cp -rf /etc/asterisk /etc/asterisk.bak >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Copying files" "$GREEN [ Done ] $NORMAL"
	fi
	
	echo -ne 'installation starting time\r ' > /var/log/nixxis/installation.log
	echo "$(date)" >> /var/log/nixxis/installation.log 2>&1
	printf '\n %-25s %s\n ' " " "$CYAN======== Installing prerequisites =========$NORMAL"
	printf '\n %-25s %s\n ' " " "$CYAN======== Installing prerequisites =========$NORMAL" >> /var/log/nixxis/installation.log
# ensure Time Is Correct
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Starting & checking ntp" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Starting & checking ntp" "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Starting ntp" "$NORMAL [ ... ] $NORMAL"
	if systemctl status  chronyd.service | grep "Loaded: " | grep -q "loaded" > /dev/null 2>&1; then
		if systemctl status  chronyd.service | grep "Active: " | grep -q "inactive" > /dev/null 2>&1; then
		
			systemctl enable chronyd.service >> /var/log/nixxis/installation.log 2>&1
			ntpdate pool.ntp.org >> /var/log/nixxis/installation.log 2>&1
			systemctl start ntpd.service >> /var/log/nixxis/installation.log 2>&1
								
			if systemctl status  chronyd.service | grep "Active: " | grep -q "active" > /dev/null 2>&1; then
				printf '%-*s %s\n ' $col "Starting ntp" "$GREEN [ ✓ Ok ] $NORMAL"
				printf '%-*s %s\n ' $col "Starting ntp" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			else
				printf '%-*s %s\n ' $col "Starting ntp" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
			fi
		
		else
#systemctl stop ntpd.service >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Starting ntp" "$NORMAL [ Nothing To Do ] $NORMAL"
			printf '%-*s %s\n ' $col "Starting ntp" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log		
		fi
			
	else
		printf '%-*s %s\n ' $col "Starting ntp" "$RED [ ✗ Fail ] $NORMAL"
		echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
		((failcount++))
	fi
	
	printf '\n %-30s %s\n ' "Actual date : " "$(date)" 
	printf '\n %-30s %s\n ' "Actual date : " "$(date)" >> /var/log/nixxis/installation.log
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Disabling iptables & selinux" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Disabling iptables & selinux" "#####$NORMAL" >> /var/log/nixxis/installation.log
# disabling iptables
	printf '%-*s %s\r ' $col "Stopping iptables" "$NORMAL [ ... ] $NORMAL"
	if service iptables status > /dev/null 2>&1; then
		service iptables stop >> /var/log/nixxis/installation.log 2>&1
		chkconfig iptables off >> /var/log/nixxis/installation.log 2>&1
		if service iptables status >> /var/log/nixxis/installation.log 2>&1; then
			printf '%-*s %s\n ' $col "Stopping iptables" "$RED [ ✗ Fail ] $NORMAL"
			echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
			((failcount++))
		else
			printf '%-*s %s\n ' $col "Stopping iptables" "$ORANGE [ Restart Needed ] $NORMAL" 
			printf '%-*s %s\n ' $col "Stopping iptables" "$ORANGE [ Restart Needed ] $NORMAL" >> /var/log/nixxis/installation.log
			#isrestartneeded="true"
		fi
	else
		printf '%-*s %s\n ' $col "Stopping iptables" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Stopping iptables" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	
	
	printf '%-*s %s\r ' $col "Stopping ip6tables" "$NORMAL [ ... ] $NORMAL"
	if service ip6tables status > /dev/null 2>&1; then
		service ip6tables stop >> /var/log/nixxis/installation.log 2>&1
		chkconfig ip6tables off >> /var/log/nixxis/installation.log 2>&1
		if service ip6tables status >> /var/log/nixxis/installation.log 2>&1; then
			printf '%-*s %s\n ' $col "Stopping ip6tables" "$RED [ ✗ Fail ] $NORMAL"
			echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
			((failcount++))
		else
			printf '%-*s %s\n ' $col "Stopping ip6tables" "$GREEN [ ✓ Ok ] $NORMAL"
			printf '%-*s %s\n ' $col "Stopping ip6tables" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			#isrestartneeded="true"
		fi
	else
		printf '%-*s %s\n ' $col "Stopping ip6tables" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Stopping ip6tables" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	printf '%-*s %s\r ' $col "Stopping firewalld" "$NORMAL [ ... ] $NORMAL"
	if systemctl status firewalld.service | grep "Loaded: " | grep -q "loaded" > /dev/null 2>&1; then
		service firewalld stop >> /var/log/nixxis/installation.log 2>&1
		chkconfig firewalld off >> /var/log/nixxis/installation.log 2>&1
		if service firewalld status >> /var/log/nixxis/installation.log 2>&1; then
			printf '%-*s %s\n ' $col "Stopping firewalld" "$RED [ ✗ Fail ] $NORMAL"
			echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
			((failcount++))
		else
			printf '%-*s %s\n ' $col "Stopping firewalld" "$GREEN [ ✓ Ok ] $NORMAL"
			printf '%-*s %s\n ' $col "Stopping firewalld" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			#isrestartneeded="true"
		fi
	else
		printf '%-*s %s\n ' $col "Stopping firewalld" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Stopping firewalld" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	
# disabling SELINUX
	printf '%-*s %s\r ' $col "Stopping selinux" "$NORMAL [ ... ] $NORMAL"
	if getenforce | grep -q "Enforcing" > /dev/null 2>&1; then
		sed -i "s/[\s]*SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config 
		setenforce 0 >> /var/log/nixxis/installation.log 2>&1
		if getenforce | grep -q "Enforcing" > /dev/null 2>&1; then
			printf '%-*s %s\n ' $col "Stopping selinux" "$RED [ ✗ Fail ] $NORMAL"
			echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
			((failcount++))
		else
			printf '%-*s %s\n ' $col "Stopping selinux" "$GREEN [ ✓ Ok ] $NORMAL" 
			printf '%-*s %s\n ' $col "Stopping selinux" "$GREEN [ ✓ Ok ] $NORMAL"  >> /var/log/nixxis/installation.log
			isrestartneeded="true"
		fi
	else
		printf '%-*s %s\n ' $col "Stopping selinux" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Stopping selinux" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing dependencies" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing dependencies" "#####$NORMAL" >> /var/log/nixxis/installation.log
# Adding EPEL repository
	printf '%-*s %s\r ' $col "Adding EPEL repository" "$NORMAL [ ... ] $NORMAL"
	
	if yum -y install epel-release >> /var/log/nixxis/installation.log 2>&1; then
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$GREEN [ ✓ Ok ] $NORMAL" 
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	
# updating installation
	printf '%-*s %s\r ' $col "Updating yum" "$NORMAL [ ... ] $NORMAL"
	crb enable >> /var/log/nixxis/installation.log 2>&1;
	if yum update -y >> /var/log/nixxis/installation.log 2>&1; then
		printf '%-*s %s\n ' $col "Updating yum" "$GREEN [ ✓ Ok ] $NORMAL" 
		printf '%-*s %s\n ' $col "Updating yum" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		printf '%-*s %s\n ' $col "Updating yum" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Updating yum" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	
	if [ "$isrestartneeded" = "true" ] ; then
		printf '\n\n %-25s %s\n ' " " "$ORANGE ---  Server must be restart  --- $NORMAL"
		printf '\n\t The script has performed some action and the server must be restart.'
		printf '\n\t Anyway you can also skip this step at you own risk.\n\n \t\t '
		read -p 'do you want to reboot now ? [Y/n]' Flag
		if [ "$Flag" != "N" ] && [ "$Flag" != "n" ] && [ "$Flag" != "no" ] && [ "$Flag" != "No" ] ; then
			reboot
			exit
		fi
		printf '\n '
	fi
# Packages Installation
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing packages" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing packages" "#####$NORMAL" >> /var/log/nixxis/installation.log
	
# mandatory packages
	printf '%-15s %s\n ' "$ORANGE-----" "mandatory packages$NORMAL"
	yum install -y "Development Tools" >> /var/log/nixxis/installation.log 2>&1
	for pkg in ${packages[*]}; do
		printf '%-*s %s\r ' $col "Installing $pkg" "$NORMAL [ ... ] $NORMAL"
		if rpm -qa | grep  $pkg > /dev/null 2>&1; then
			printf '%-*s %s\n ' $col "Installing $pkg" "$NORMAL [ Nothing To Do ] $NORMAL" 
			printf '%-*s %s\n ' $col "Installing $pkg" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
		else
			if yum install -y $pkg >> /var/log/nixxis/installation.log 2>&1; then
				printf '%-*s %s\n ' $col "Installing $pkg" "$GREEN [ ✓ Ok ] $NORMAL" 
				printf '%-*s %s\n ' $col "Installing $pkg" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			else
				printf '%-*s %s\n ' $col "Installing $pkg" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
			fi
		fi
	done
	yum install -y tar >> /var/log/nixxis/installation.log 2>&1
# Simple network monitoring protocol (SNMP)
	printf '%-15s %s\n ' "$ORANGE-----" "Simple network monitoring protocol (SNMP)$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Simple network monitoring protocol (SNMP)$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Installing snmp" "$NORMAL [ ... ] $NORMAL"
	if systemctl status  snmpd.service | grep "Loaded: " | grep -q "loaded" > /dev/null 2>&1; then
		if systemctl status  snmpd.service | grep "Active: " | grep -q "inactive" > /dev/null 2>&1; then
			systemctl enable snmpd.service >> /var/log/nixxis/installation.log 2>&1
			systemctl start snmpd.service >> /var/log/nixxis/installation.log 2>&1
								
			if systemctl status  snmpd.service | grep "Active: " | grep -q "active" > /dev/null 2>&1; then
				printf '%-*s %s\n ' $col "Starting snmp" "$GREEN [ ✓ Ok ] $NORMAL"
				printf '%-*s %s\n ' $col "Starting snmp" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			else
				printf '%-*s %s\n ' $col "Starting snmp" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
			fi		
		else						
			printf '%-*s %s\n ' $col "Installing snmp" "$NORMAL [ Nothing To Do ] $NORMAL" 
			printf '%-*s %s\n ' $col "Installing snmp" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
		fi
	fi
# Activate cgi module
	printf '%-15s %s\n ' "$ORANGE-----" "Activating cgi module$NORMAL"
	printf '%-15s %s\n ' "$ORANGE-----" "Activating cgi module$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/lighttpd/modules.conf" "$NORMAL [ ... ] $NORMAL"
	sed -i 's|.*\#include \"conf.d/cgi.conf\".*|\include \"conf.d/cgi.conf\"|' /etc/lighttpd/modules.conf
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/modules.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/modules.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/lighttpd/conf.d/cgi.conf" "$NORMAL [ ... ] $NORMAL"
	rm -rf /etc/lighttpd/conf.d/cgi.conf >> /var/log/nixxis/installation.log 2>&1
	touch /etc/lighttpd/conf.d/cgi.conf >> /var/log/nixxis/installation.log 2>&1
	echo 'server.modules += ( "mod_cgi" )' >> /etc/lighttpd/conf.d/cgi.conf
	echo 'cgi.assign = ( "" => "" )' >> /etc/lighttpd/conf.d/cgi.conf
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/conf.d/cgi.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/conf.d/cgi.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Customizing nano
	printf '%-15s %s\n ' "$ORANGE-----" "Installing & Customizing nano$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Installing & Customizing nano$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Installing nano" "$NORMAL [ ... ] $NORMAL"
	if rpm -qa | grep  nano > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Installing nano" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Installing nano" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		if yum install -y nano >> /var/log/nixxis/installation.log 2>&1; then
				printf '%-*s %s\n ' $col "Installing nano" "$GREEN [ ✓ Ok ] $NORMAL" 
				printf '%-*s %s\n ' $col "Installing nano" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
		else
				printf '%-*s %s\n ' $col "Installing nano" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
		fi
	fi
	printf '%-*s %s\r ' $col "Customizing nano" "$NORMAL [ ... ] $NORMAL" 
	printf '%-*s %s\r ' $col "Customizing nano" "$NORMAL [ ... ] $NORMAL" >> /var/log/nixxis/installation.log
	cp -f /etc/nanorc.bak /etc/nanorc
	cp -f /etc/nanorc /etc/nanorc.bak
	echo 'include "/usr/share/nano/asterisk.nanorc"' >> /etc/nanorc
#Now it's a colorful life for the Asterisk
	echo 'include "/usr/share/nano/php.nanorc"' >> /etc/nanorc
	echo 'include "/usr/share/nano/html.nanorc"' >> /etc/nanorc
	echo 'include "/usr/share/nano/sh.nanorc"' >> /etc/nanorc
	mkdir -p /usr/share/nano >> /var/log/nixxis/installation.log 2>&1
	cd /usr/share/nano >> /var/log/nixxis/installation.log 2>&1
	mv -f sh.nanorc sh2.nanorc >> /var/log/nixxis/installation.log 2>&1
	wget https://bitbucket.org/NixxisSupport/nixxis-nms-installation/downloads/asterisk.nanorc >> /var/log/nixxis/installation.log 2>&1
	wget https://bitbucket.org/NixxisSupport/nixxis-nms-installation/downloads/php.nanorc >> /var/log/nixxis/installation.log 2>&1
	wget https://bitbucket.org/NixxisSupport/nixxis-nms-installation/downloads/sh.nanorc >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Customizing nano" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Customizing nano" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Configuring modules" "#####$NORMAL"  
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Configuring modules" "#####$NORMAL" >> /var/log/nixxis/installation.log
# Activate cgi module
	printf '%-15s %s\n ' "$ORANGE-----" "Activating cgi module$NORMAL"
	printf '%-15s %s\n ' "$ORANGE-----" "Activating cgi module$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/lighttpd/modules.conf" "$NORMAL [ ... ] $NORMAL"
	sed -i 's|.*\#include \"conf.d/cgi.conf\".*|\include \"conf.d/cgi.conf\"|' /etc/lighttpd/modules.conf
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/modules.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/modules.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/lighttpd/conf.d/cgi.conf" "$NORMAL [ ... ] $NORMAL"
	rm -rf /etc/lighttpd/conf.d/cgi.conf >> /var/log/nixxis/installation.log 2>&1
	touch /etc/lighttpd/conf.d/cgi.conf >> /var/log/nixxis/installation.log 2>&1
	echo 'server.modules += ( "mod_cgi" )' >> /etc/lighttpd/conf.d/cgi.conf
	echo 'cgi.assign = ( "" => "" )' >> /etc/lighttpd/conf.d/cgi.conf
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/conf.d/cgi.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/conf.d/cgi.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# downloading the packages
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Downloading packages" "#####$NORMAL"  
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Downloading packages" "#####$NORMAL"  >> /var/log/nixxis/installation.log
	mkdir /usr/src/asterisk >> /var/log/nixxis/installation.log 2>&1
	cd /usr/src/asterisk >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\r ' $col "Downloading asterisk" "$NORMAL [ ... ] $NORMAL"
	wget $Asterisk >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Downloading asterisk" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Downloading asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Uncompressing asterisk" "$NORMAL [ ... ] $NORMAL"
	tar zxvf $AsteriskVersionComp >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Uncompressing asterisk" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Uncompressing asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
#skip hardware drivers unless needed
	if [ "$installhardware" = "true" ] ; then
		printf '%-*s %s\r ' $col "Downloading dahdi" "$NORMAL [ ... ] $NORMAL"
		wget http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Downloading dahdi" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Downloading dahdi" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Uncompressing dahdi" "$NORMAL [ ... ] $NORMAL"
		tar zxvf dahdi-linux-complete-current.tar.gz >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Uncompressing dahdi" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Uncompressing dahdi" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Downloading libpri" "$NORMAL [ ... ] $NORMAL"
		wget http://downloads.asterisk.org/pub/telephony/libpri/releases/libpri-1.4.3.tar.gz >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Downloading libpri" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Downloading libpri" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Uncompressing libpri" "$NORMAL [ ... ] $NORMAL"
		tar zxvf libpri-1.4.3.tar.gz >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Uncompressing libpri" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Uncompressing libpri" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
# Downloading and installing hardware/IAX2 support drivers
	if [ "$installhardware" = "true" ] ; then
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing hardware/IAX2 support drivers" "#####$NORMAL" 
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing hardware/IAX2 support drivers" "#####$NORMAL" >> /var/log/nixxis/installation.log
		
		printf '%-15s %s\n ' "$ORANGE-----" "Installing Dahdi$NORMAL" 
		printf '%-15s %s\n ' "$ORANGE-----" "Installing Dahdi$NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Building dahdi" "$NORMAL [ ... ] $NORMAL"
		cd /usr/src/asterisk/dahdi-linux-complete*/  >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building dahdi (make all)" "$NORMAL [ ... ] $NORMAL"
		make  >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building dahdi (make install)" "$NORMAL [ ... ] $NORMAL"
		make install >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building dahdi (make config)" "$NORMAL [ ... ] $NORMAL"
		make config >> /dev/null 2>&1
		if lsmod | grep dahdi > /dev/null 2>&1; then
			printf '%-*s %s\n ' $col "Building dahdi" "$GREEN [ ✓ Ok ] $NORMAL" 
			printf '%-*s %s\n ' $col "Building dahdi" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
		else
			/etc/init.d/dahdi start >> /var/log/nixxis/installation.log 2>&1
			service dahdi start >> /var/log/nixxis/installation.log 2>&1
			if lsmod | grep dahdi > /dev/null 2>&1; then
				printf '%-*s %s\n ' $col "Building dahdi" "$GREEN [ ✓ Ok ] $NORMAL" 
				printf '%-*s %s\n ' $col "Building dahdi" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			else			
				echo -ne " $RED ####################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
				printf '%-*s %s\n ' $col "Building dahdi" "$RED [ ✗ Fail ] $NORMAL" 
				printf '%-*s %s\n ' $col "Building dahdi" "$RED [ ✗ Fail ] $NORMAL" >> /var/log/nixxis/installation.log
				printf '\n\n %-25s %s\n ' " " "$RED ---  Error while installing Asterisk  --- $NORMAL"
				printf '\n\t An unexpected error occured while installing dahdi. '
				printf '\n\t The Dahdi services cannot be started. '
				printf '\n\t Please check /var/log/nixxis/installation.log for more imformation.\n\n \t\t '
				read -p 'do you want to continue anyway ? [y/N]' Flag
				if [ "$Flag" != "Y" ] && [ "$Flag" != "y" ] && [ "$Flag" != "Yes" ] && [ "$Flag" != "yes" ] ; then
					exit
				fi
				printf '\n '
			fi
		fi
	
		printf '%-15s %s\n ' "$ORANGE-----" "Installing Libpri$NORMAL" 
		printf '%-15s %s\n ' "$ORANGE-----" "Installing Libpri$NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Building libpri" "$NORMAL [ ... ] $NORMAL"
		cd /usr/src/asterisk/libpri-1.4*/ >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building libpri (make clean)" "$NORMAL [ ... ] $NORMAL"
		make clean >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building libpri (make)" "$NORMAL [ ... ] $NORMAL"
		make >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building libpri (make install)" "$NORMAL [ ... ] $NORMAL"
		make install >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Building libpri" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Building libpri" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing Asterisk*" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing Asterisk*" "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-15s %s\n ' "$ORANGE-----" "Installing Asterisk*$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Installing Asterisk*$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Execute ./configure" "$NORMAL [ ... ] $NORMAL"
	cd /usr/src/asterisk/$AsteriskVersion >> /var/log/nixxis/installation.log 2>&1
	contrib/scripts/install_prereq install >> /var/log/nixxis/installation.log 2>&1
	./configure --libdir=/usr/lib64 --with-jansson-bundled=yes >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Execute ./configure" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Execute ./configure" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Building asterisk* (make menuselect)" "$NORMAL [ ... ] $NORMAL"

	make menuselect.makeopts
	menuselect/menuselect --disable BUILD_NATIVE --enable CHAN_SIP --enable CORE-SOUNDS-EN-ALAW --enable CORE-SOUNDS-EN-GSM --enable CORE-SOUNDS-EN-WAV --enable CORE-SOUNDS-EN-G729 --enable CORE-SOUNDS-FR-ALAW --enable CORE-SOUNDS-FR-GSM --enable CORE-SOUNDS-FR-WAV --enable CORE-SOUNDS-FR-G729 --enable MOH-OPSOUND-ULAW --enable MOH-OPSOUND-ALAW --enable MOH-OPSOUND-GSM --enable MOH-OPSOUND-G729 --enable EXTRA-SOUNDS-EN-WAV --enable EXTRA-SOUNDS-EN-ALAW --enable EXTRA-SOUNDS-EN-GSM --enable EXTRA-SOUNDS-EN-G729 --enable EXTRA-SOUNDS-FR-WAV --enable EXTRA-SOUNDS-FR-ALAW --enable EXTRA-SOUNDS-FR-GSM --enable EXTRA-SOUNDS-FR-G729 save 
	printf '%-*s %s\r ' $col "Building asterisk* (make)" "$NORMAL [ ... ] $NORMAL"
	make >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\r ' $col "Building asterisk* (make install)" "$NORMAL [ ... ] $NORMAL"
	make install >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Building asterisk*" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Building asterisk*" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Creating config files" "$NORMAL [ ... ] $NORMAL"
	make samples >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating config files" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Creating config files" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	make config >> /var/log/nixxis/installation.log 2>&1
	ldconfig >> /var/log/nixxis/installation.log 2>&1
# Automatically start Asterisk on server boot
	#####################################TO CHECK THE FOLLOWING ----------------> 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Setup start on wakeup" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Setup start on wakeup" "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Copying files" "$NORMAL [ ... ] $NORMAL" 
	# Création du fichier systemd pour Asterisk
echo "Création du fichier systemd pour Asterisk..."
cat <<EOF > /etc/systemd/system/asterisk.service
[Unit]
Description=Asterisk PBX and telephony daemon.
After=network.target

[Service]
Type=simple
Environment=HOME=/var/lib/asterisk
WorkingDirectory=/var/lib/asterisk
User=sounds
Group=sounds
ExecStart=/usr/sbin/asterisk -f -C /etc/asterisk/asterisk.conf
ExecStop=/usr/sbin/asterisk -rx 'core stop now'
ExecReload=/usr/sbin/asterisk -rx 'core reload'
RuntimeDirectory=asterisk
LimitCORE=infinity
Restart=always
RestartSec=4
StandardOutput=null
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF
	ln -s /etc/systemd/system/asterisk.service /etc/systemd/system/multi-user.target.wants/asterisk.service
	systemctl daemon-reload
	chkconfig --add asterisk
	chkconfig asterisk on

	if [ "$config_core_lang_NL" = "true" ] ; then
		printf '%-15s %s\n ' "$ORANGE[EXTRA]" "Installing Dutch languages patch$NORMAL" 
		printf '%-15s %s\n ' "$ORANGE[EXTRA]" "Installing Dutch languages patch$NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Downloading Dutch languages patch" "$NORMAL [ ... ] $NORMAL"
		mkdir -p /var/lib/asterisk/sounds/nl/ >> /var/log/nixxis/installation.log 2>&1
		cd /var/lib/asterisk/sounds/nl/ >> /var/log/nixxis/installation.log 2>&1
		wget http://www.gosselaar.net/trixbox/NL-sounds.tar.gz >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Downloading Dutch languages patch" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Downloading Dutch languages patch" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Uncompressing Dutch languages patch" "$NORMAL [ ... ] $NORMAL"
		tar zxvf NL-sounds.tar.gz >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Uncompressing Dutch languages patch" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Uncompressing Dutch languages patch" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Setup Nixxis Pack" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Setup Nixxis Pack" "#####$NORMAL" >> /var/log/nixxis/installation.log
	# downloading nixxis pack
	printf '%-*s %s\r ' $col "Downloading Nixxis pack" "$NORMAL [ ... ] $NORMAL"
	pushd /usr/src/asterisk/ >> /var/log/nixxis/installation.log 2>&1
	wget -O NixxisInstall.zip $NixxisUri >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Downloading Nixxis pack" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Downloading Nixxis pack" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# unpacking
	printf '%-*s %s\r ' $col "Unpacking Nixxis pack" "$NORMAL [ ... ] $NORMAL" 
	yum install -y unzip >> /var/log/nixxis/installation.log 2>&1
	mkdir /usr/src/asterisk/nixxis
	unzip -o NixxisInstall.zip -d /usr/src/asterisk/nixxis >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Unpacking Nixxis pack" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Unpacking Nixxis pack" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Installing Nixxis Asterisk configuration files
	printf '%-*s %s\r ' $col "Placing Nixxis pack elements" "$NORMAL [ ... ] $NORMAL"
	cp -rf /usr/src/asterisk/nixxis/MediaServer/etc/* /etc >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/usr/* /usr >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/var/* /var >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/srv/* /srv >> /var/log/nixxis/installation.log 2>&1
	chmod a+x /usr/sbin/* >> /var/log/nixxis/installation.log 2>&1
	chmod a+x /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	dos2unix /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	chmod a+x /var/lib/asterisk/agi-bin/* >> /var/log/nixxis/installation.log 2>&1
	mkdir /etc/asterisk/nixxis/custom >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Placing Nixxis pack elements" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Placing Nixxis pack elements" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Asterisk* Configuration" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Asterisk* Configuration" "#####$NORMAL" >> /var/log/nixxis/installation.log
#Creating IVR and Recording users
	printf '%-15s %s\n ' "$ORANGE-----" "Creating users$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Creating users$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Creating User sounds" "$NORMAL [ ... ] $NORMAL" 
	adduser sounds >> /var/log/nixxis/installation.log 2>&1
	echo -ne "${pbxsound}\n${pbxsound}" | passwd sounds >> /var/log/nixxis/installation.log 2>&1
	chmod 700 /home/sounds >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating User sounds (password: ${pbxsound})" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Creating User sounds (password: ${pbxsound})" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Creating User recording" "$NORMAL [ ... ] $NORMAL"
	adduser recording >> /var/log/nixxis/installation.log 2>&1
	echo -ne "${pbxrecor}\n${pbxrecor}" | passwd recording >> /var/log/nixxis/installation.log 2>&1
	chmod 700 /home/recording >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating User recording (password: ${pbxrecor})" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Creating User recording (password: ${pbxrecor})" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Web-server installation and configuration
	printf '%-15s %s\n ' "$ORANGE-----" "Configuring web-server$NORMAL"  
	printf '%-15s %s\n ' "$ORANGE-----" "Configuring web-server$NORMAL"  >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing right" "$NORMAL [ ... ] $NORMAL" 
	chgrp recording /var/log/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	chmod g+w /var/log/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/lighttpd/lighttpd.conf" "$NORMAL [ ... ] $NORMAL" 
	sed -i 's^var.server_root = "/var/www"^var.server_root = "/srv/www"^' /etc/lighttpd/lighttpd.conf
	sed -i 's|.*server.username  = "lighttpd".*|server.username  = "recording"|' /etc/lighttpd/lighttpd.conf
	sed -i 's|.*server.groupname = "lighttpd".*|server.groupname = "recording"|' /etc/lighttpd/lighttpd.conf
	sed -i 's/^#server.max-fds = 2048/server.max-fds = 2048/' /etc/lighttpd/lighttpd.conf
	sed -i 's|.*server.use-ipv6 = "enable"|server.use-ipv6 = "disable"|' /etc/lighttpd/lighttpd.conf
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Stopping lighttpd" "$NORMAL [ ... ] $NORMAL" 
	systemctl stop lighttpd.service >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing right for recording user" "$NORMAL [ ... ] $NORMAL" 
	chown recording:recording /var/log/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	chown recording:recording /var/log/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	chown recording:recording /srv/www/lighttpd >> /var/log/nixxis/installation.log 2>&1
	chown recording:recording /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	chmod 700  /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Starting lighttpd" "$NORMAL [ ... ] $NORMAL" 
	
	systemctl start lighttpd.service >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Starting lighttpd" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Starting lighttpd" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/lighttpd/lighttpd.conf" "$NORMAL [ ... ] $NORMAL"  
	cd /etc/asterisk >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/lighttpd.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/lighttpd.conf" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
# Adapting config files
	printf '%-15s %s\n ' "$ORANGE-----" "Editing Configuration files$NORMAL"
	printf '%-15s %s\n ' "$ORANGE-----" "Editing Configuration files$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/asterisk/manager.conf" "$NORMAL [ ... ] $NORMAL"
	sed -i 's/^enabled = no/enabled = yes/' /etc/asterisk/manager.conf
	echo -e '\n[nixxis]' >> /etc/asterisk/manager.conf >> /etc/asterisk/manager.conf
	echo 'secret=nixxis00' >> /etc/asterisk/manager.conf >> /etc/asterisk/manager.conf
	echo 'read = system,call,log,verbose,command,agent,user,config' >> /etc/asterisk/manager.conf
	echo 'write = system,call,log,verbose,command,agent,user,config' >> /etc/asterisk/manager.conf
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/manager.conf" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/manager.conf" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
# Installing Nixxis V2 related options 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing Nixxis V2 related options " "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing Nixxis V2 related options " "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing Nixxis files" "$NORMAL [ ... ] $NORMAL" 
	touch /etc/asterisk/musiconhold_nixxis.conf >> /var/log/nixxis/installation.log 2>&1
	chmod 775 /etc/asterisk/musiconhold_nixxis.conf
	chown sounds:sounds /etc/asterisk/musiconhold_nixxis.conf >> /var/log/nixxis/installation.log 2>&1
	sed -i '$a#include "musiconhold_nixxis.conf"' /etc/asterisk/musiconhold.conf
	printf '%-*s %s\n ' $col "Editing Nixxis files" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing Nixxis files" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# /etc/asterisk/modules.conf
	printf '%-*s %s\r ' $col "Editing /etc/asterisk/modules.conf" "$NORMAL [ ... ] $NORMAL" 
	sed -i 's|.*preload => res_odbc.so$|preload => res_odbc.so|' /etc/asterisk/modules.conf
	sed -i 's|.*preload => res_config_odbc.so$|preload => res_config_odbc.so|' /etc/asterisk/modules.conf
	sed -i 's/^noload = chan_sip.so/load = chan_sip.so/' /etc/asterisk/modules.conf
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/modules.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/modules.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# CLI> module reload res_odbc.so
systemctl daemon-reload
	if systemctl status asterisk.service > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Checking Installation" "$GREEN [ ✓ Ok ] $NORMAL" 
		printf '%-*s %s\n ' $col "Checking Installation" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		printf '%-*s %s\n ' $col "Checking Installation" "$RED [ ✗ Fail ] $NORMAL" 
		printf '%-*s %s\n ' $col "Checking Installation" "$RED [ ✗ Fail ] $NORMAL" >> /var/log/nixxis/installation.log
		printf ' %-*s %s\r ' $col " Starting Asterisk" "$NORMAL [ ... ] $NORMAL"
		systemctl start asterisk.service >> /var/log/nixxis/installation.log 2>&1
		
		printf ' %-*s %s\n ' $col " Starting Asterisk" "$GREEN [ Done ] $NORMAL" 
		printf ' %-*s %s\n ' $col " Starting Asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Checking Installation (2)" "$NORMAL [ ... ] $NORMAL"
	   if systemctl status asterisk.service > /dev/null 2>&1; then
			printf '%-*s %s\n ' $col "Checking Installation (2)" "$GREEN [ ✓ Ok ] $NORMAL" 
			printf '%-*s %s\n ' $col "Checking Installation (2)" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
	   else
			echo -ne " $RED ####################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
			((failcount++))
			printf '%-*s %s\n ' $col "Checking Installation (2)" "$RED [ ✗ Fail ] $NORMAL"
			printf '\n\n %-25s %s\n ' " " "$RED ---  Error while installing Asterisk  --- $NORMAL" 
			printf '\n\n %-25s %s\n ' " " "$RED ---  Error while installing Asterisk  --- $NORMAL" >> /var/log/nixxis/installation.log
			printf '\n\t An unexpected error occured while installing asterisk. '
			printf '\n\t The Asterisk services cannot be started. '
			printf '\n\t Please check /var/log/nixxis/installation.log for more imformation.\n\n \t\t '
		fi
	fi
	
# SuDo manipulation
	printf '%-*s %s\r ' $col "Editing Sudoers" "$NORMAL [ ... ] $NORMAL" 
	sed -i 'N;s|\## Command Aliases\n\## These are groups of related commands\...|\## Command Aliases\n\## Asterisk\nCmnd\_Alias ASTERISK = \/usr\/sbin\/asterisk, /usr/bin/perl\n|' /etc/sudoers
	sed -i 's|^Defaults    requiretty$|\#Defaults    requiretty\n|' /etc/sudoers
	echo -e 'recording  ALL= NOPASSWD: ASTERISK' >> /etc/sudoers
	echo -e 'recording  ALL= NOPASSWD: /usr/sbin/asterisk -rx "moh reload"' >> /etc/sudoers
	echo -e 'sounds  ALL= NOPASSWD: ASTERISK' >> /etc/sudoers
	printf '%-*s %s\n ' $col "Editing Sudoers" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing Sudoers" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
# Demande l'IP de l'utilisateur via whiptail
IP=$(whiptail --inputbox "Veuillez entrer l'adresse IP de votre trunk PJSIP" 8 78 --title "Configuration Trunk PJSIP" 3>&1 1>&2 2>&3)

# Vérifie si l'utilisateur a annulé
if [ $? -eq 0 ]; then
    echo "Adresse IP saisie : $IP"
else
    echo "Annulation de l'utilisateur."
    exit 1
fi

# Configuration du trunk SIP
PJSIP_CONFIG_FILE="/etc/asterisk/sip.conf"

# Sauvegarde du fichier de configuration existant
cp $PJSIP_CONFIG_FILE $PJSIP_CONFIG_FILE.bak

# Ajoute la configuration du trunk PJSIP
cat <<EOL >> $PJSIP_CONFIG_FILE
[general]
constantssrc=yes
context=undefined
allowoverlap=no
udpbindaddr=0.0.0.0
tcpenable=no
tcpbindaddr=0.0.0.0
transport=udp
srvlookup=yes
ignoresdpversion=yes
t1min=500
useragent=Nixxis

[AppServer]
type=friend
context=nixxis
fromdomain=$IP
host=$IP
dtmfmode=info
disallow=all
allow=alaw
directmedia=no
canreinvite=no
qualify=yes
nat=no
;sendrpid=yes
trustrpid=yes
rpid_update=no

EOL
useradd -r -d /var/lib/asterisk -g sounds sounds
chown -R sounds.sounds /etc/asterisk /var/{lib,log,spool}/asterisk /usr/lib64/asterisk
restorecon -vr {/etc/asterisk,/var/lib/asterisk,/var/log/asterisk,/var/spool/asterisk}
sed -i -e 's/^#AST_USER="asterisk"/AST_USER="sounds"/' -e 's/^#AST_GROUP="asterisk"/AST_GROUP="sounds"/' -e 's/^AST_USER="asterisk"/AST_USER="sounds"/' -e 's/^AST_GROUP="asterisk"/AST_GROUP="sounds"/' /etc/sysconfig/asterisk
sed -i -e 's/^;runuser = asterisk/runuser = sounds/' -e 's/^;rungroup = asterisk/rungroup = sounds/' /etc/asterisk/asterisk.conf

systemctl restart asterisk.service >> /var/log/nixxis/installation.log 2>&1
	
# Définissez le contenu de vos nouvelles tâches cron dans une variable
new_cron_entries="
0 21 * * * /usr/sbin/nixxis_mp3_converter.sh >> /var/log/nixxis_mp3mix.log
30 4 * * * /usr/sbin/tmpwatch 30d /home/recording/
30 11 * * * /home/nixxis/remove_nixxis_mp3.lock.sh
"
# Créez un fichier temporaire pour stocker les tâches actuelles et les nouvelles tâches
temp_cron_file=$(mktemp)
# Copiez les tâches cron actuelles dans le fichier temporaire
crontab -l > "$temp_cron_file"
# Ajoutez vos nouvelles tâches à la fin du fichier temporaire
echo "$new_cron_entries" >> "$temp_cron_file"
# Importez le fichier modifié dans la crontab
crontab "$temp_cron_file"
# Supprimez le fichier temporaire
rm "$temp_cron_file"
echo -e "Nouvelles tâches cron ajoutées avec succès." >> /var/log/nixxis/installation.log
systemctl enable --now cockpit.socket


# Setup of sound file synchronization 
	printf '%-*s %s\r ' $col "Creating shared directory" "$NORMAL [ ... ] $NORMAL" 
	mkdir /home/soundsv2 >> /root/Nixxis-configuration.log 2>&1
	chown sounds:sounds /home/soundsv2  >> /root/Nixxis-configuration.log 2>&1
	printf '%-*s %s\n ' $col "Creating shared directory" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\r ' $col "Checking Installation" "$NORMAL [ ... ] $NORMAL"
	
	
	
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installation completed" "#####$NORMAL"
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installation completed" "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '\n\n %-25s %s\n ' " " "$CYAN ---  Congratulations!  --- $NORMAL" 
	printf '\n\n %-25s %s\n ' " " "$CYAN ---  Congratulations!  --- $NORMAL" >> /var/log/nixxis/installation.log
	printf '\n\t You just finish the installation of your Nixxis MediaServer. You will need to restart the Media server'
	if [ "$failcount" -gt "0" ]	; then
		printf "\n\t $RED $failcount Fail $NORMAL has appeared while the installation please check logs file for more details "
	fi
	printf '\n '
	read -p "Press any key to exit the script."

}

nms_update(){

	# Check if os is supported Rocky Linux.
	if rpm -qa \*-release | grep -Ei "Rocky" | cut -d"-" -f3 | grep -iho "9" > /dev/null 2>&1; then
                        osversion="9"
                        if uname -m | grep -q "x86_64" > /dev/null 2>&1; then
                                osarch="64"
                                echo "Rocky Linux 9 64bit Installed" >> /var/log/nixxis/installation.log
                        else
                                echo "Rocky Linux 9 32bit Installed" >> /var/log/nixxis/installation.log
                        fi

        else
                        printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "This installation of Nixxis is for Rocky Linux 9 only"
                        printf '\n\n %-25s %s\n ' " " "$RED This installation of Nixxis is for Rocky Linux 9 only $NORMAL" >> /var/log/nixxis/installation.log
                        exit
        fi
    printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "OS Rocky Linux $osversion installed"
	
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Backing up old Nixxis File" "#####$NORMAL"
	#Copying files
	printf '%-*s %s\r ' $col "Copying files" "$NORMAL [ ... ] $NORMAL"
	cp -rf /etc/asterisk /etc/asterisk.bak >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Copying files" "$GREEN [ Done ] $NORMAL"
	
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Update Nixxis File" "#####$NORMAL"	
	# downloading nixxis pack
	printf '%-*s %s\r ' $col "Downloading Nixxis pack" "$NORMAL [ ... ] $NORMAL"
	cd /usr/src/asterisk/ >> /var/log/nixxis/installation.log 2>&1
	wget -O NixxisInstall.zip $NixxisUri --user install --password qR4Eqkuz >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Downloading Nixxis pack" "$GREEN [ Done ] $NORMAL"
# unpacking
	printf '%-*s %s\r ' $col "Unpacking Nixxis pack" "$NORMAL [ ... ] $NORMAL" 
	yum install -y unzip >> /var/log/nixxis/installation.log 2>&1
	mkdir /usr/src/asterisk/nixxis
	unzip -o NixxisInstall.zip -d /usr/src/asterisk/nixxis >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Unpacking Nixxis pack" "$GREEN [ Done ] $NORMAL"
# Installing Nixxis Asterisk configuration files
	printf '%-*s %s\r ' $col "Placing Nixxis pack elements" "$NORMAL [ ... ] $NORMAL"
	cp -rf /usr/src/asterisk/nixxis/MediaServer/etc/* /etc >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/usr/* /usr >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/var/* /var >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/srv/* /srv >> /var/log/nixxis/installation.log 2>&1
	chmod a+x /usr/sbin/* >> /var/log/nixxis/installation.log 2>&1
	chmod a+x /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	dos2unix /srv/www/lighttpd/MohReload >> /var/log/nixxis/installation.log 2>&1
	dos2unix /srv/www/lighttpd/syncsounds >> /var/log/nixxis/installation.log 2>&1
	dos2unix /srv/www/lighttpd/recording >> /var/log/nixxis/installation.log 2>&1
	chmod a+x /var/lib/asterisk/agi-bin/* >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Placing Nixxis pack elements" "$GREEN [ Done ] $NORMAL"
}

nms_check(){
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "checking machine state" "#####$NORMAL" 
	
	# Check if user is root.
	if [ "$UID" -ne "0" ] ; then
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "You must run this script as root"
		exit
	else
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "script is running as root"
	fi
	
	# Check if os is supported Rocky Linux.
	if rpm -qa \*-release | grep -Ei "Rocky" | cut -d"-" -f3 | grep -iho "9" > /dev/null 2>&1; then
                        osversion="9"
                        if uname -m | grep -q "x86_64" > /dev/null 2>&1; then
                                osarch="64"
                                echo "Rocky Linux 9 64bit Installed" >> /var/log/nixxis/installation.log
                        else
                                echo "Rocky Linux 9 32bit Installed" >> /var/log/nixxis/installation.log
                        fi

        else
                        printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "This installation of Nixxis is for Rocky Linux 9 only"
                        printf '\n\n %-25s %s\n ' " " "$RED This installation of Nixxis is for Rocky Linux 9 only $NORMAL" >> /var/log/nixxis/installation.log
                        exit
        fi
    printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "OS Rocky Linux $osversion installed"
	
	
	# ensure Time Is Correct
	if /etc/init.d/chronyd status > /dev/null 2>&1; then
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "ntp is not running"
	else
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "ntp is running"
	fi
	# disabling iptables
	if /etc/rc.d/init.d/iptables status > /dev/null 2>&1; then
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "iptables are running"
	else
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "iptables are not running"
	fi
	if /etc/rc.d/init.d/ip6tables status > /dev/null 2>&1; then
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "ip6tables are running"
	else
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "ip6tables are not running"
	fi
# disabling SELINUX
	if /usr/sbin/sestatus | grep "Current mode:" | grep -q "enforcing" > /dev/null 2>&1; then
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "selinux is enable"
	else
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "selinux is disable"
	fi
printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "checking packages" "#####$NORMAL" 
	for pkg in ${pkgs[*]}; do
		printf '%-*s %s\r ' 10 "$NORMAL [ . ] $NORMAL" "Cheking ${pkg}"
		if rpm -qa | grep  $pkg > /dev/null 2>&1; then
			printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "${pkg} is installed"
		else
			printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "${pkg} is not installed"
		fi
	done
	
	if [ -f /usr/lib/asterisk/modules/format_sln.so ] ; then
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "format_sln is installed"
	else
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "format_sln is not installed"
	fi
printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "checking componments" "#####$NORMAL" 
	
	if lsmod | grep dahdi > /dev/null 2>&1; then
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "dahdi is running"
	else
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "dahdi is not running"
	fi
if service asterisk status > /dev/null 2>&1; then
		printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "asterisk is running"
	else
		printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "asterisk is not running"
	fi
	
lines=$(tput lines)
columns=$(tput cols)
col3=$((columns / 3))
col2=$((columns / 2))
	
	printf '\n %-15s %-40s %s\n' "$MAGENTA#####" "checking CPU load" "#####$NORMAL" 
	
	pross=$(grep processor /proc/cpuinfo | wc -l)
	load=$(cat /proc/loadavg | cut -d' ' -f1-3)
	
	bar=$(printf '%.1s' "|"{1..25})
	space=$(printf '%.1s' " "{1..25})
	
	i=0
	min=(" 1" " 5" "15")
	for loaded in $load; do
		loading=$(float_eval "$(echo $loaded | cut -d' ' -f1) * 100")
		pc=$(float_eval "$loading / $pross")
		pv=$(float_eval "$pc / 4")
		pb=$(printf '%.0f' $pv)
		if [ "$pb" -gt "25" ] ; then
			pb=25 ; pbs=0
		else
			pbs=$((25 - $pb))
		fi
		pc=$(printf '%.1f%%' $pc)
if [ "$pb" -lt "19" ] ;	then
			COLOR=$(tput setaf 2)
		elif [ "$pb" -gt "23" ] ; then
			COLOR=$(tput setaf 1)
		else
			COLOR=$(tput setaf 3)
		fi
		toprint=$(printf '%s%s' "${min[i]} min [$COLOR${bar:0:pb}$NORMAL${space:0:pbs}] " "$pc")
		printf '  %-*.*s\n' $col3 $col3 "$toprint"
		i=$(($i + 1 ))
	done
	
	printf '\n %-15s %-40s %s\n' "$MAGENTA#####" "Running time" "#####$NORMAL"
	
	Suptime=$(uptime | cut -d',' -f1 | rev | cut -d' ' -f1-2 | rev )
	ASuptime=$(/usr/sbin/asterisk -rx "core show uptime" | grep ystem | cut -d':' -f2 | cut -d',' -f1)
	ARuptime=$(/usr/sbin/asterisk -rx "core show uptime" | grep ystem | cut -d':' -f2 | cut -d',' -f1)
printf '  %-*.*s\n' $col3 $col3 "Server uptime: $Suptime"
	printf '  %-*.*s\n' $col3 $col3 "Asterisk uptime: $(/usr/sbin/asterisk -rx "core show uptime")" 
	printf '  %-*.*s\n' $col3 $col3 ""
	
	printf '\n %-15s %-40s %s\n' "$MAGENTA#####" "SIP and IAX peers status" "#####$NORMAL"
	
	printf '%-15s %s\n' "$ORANGE-----" "SIP peers $NORMAL"
		
	/usr/sbin/asterisk -rx "sip show peers" > /tmp/peer.tmp
	while read peer ; do
		printf "\t"
		if echo $peer | grep 'OK' > /dev/null; then
			printf "$(tput setaf 2)"
			printf "$peer"
			
			printf "$NORMAL"
		elif echo $peer | grep 'LAGGED' > /dev/null; then
			printf "$(tput setaf 3)"
			printf "$peer"
			
			printf "$NORMAL"
		elif echo $peer | grep 'UNREACHABLE' > /dev/null; then
			printf "$(tput setaf 1)"
			printf "$peer"
			
			printf "$NORMAL"
		elif echo $peer | grep 'UNKNOWN' > /dev/null; then
			printf "$(tput setaf 1)"
			printf "$peer"
			
			printf "$NORMAL"
		elif echo $peer | grep 'Unmonitored' > /dev/null; then
			printf "$peer"
		fi
		printf "\n"
	done < /tmp/peer.tmp
	printf "\n"
	
	printf '%-15s %s\n' "$ORANGE-----" "IAX peers $NORMAL"
		
	/usr/sbin/asterisk -rx "iax2 show peers" > /tmp/peer.tmp
	while read peer ; do
		printf "\t"
		if echo $peer | grep 'OK' > /dev/null; then
			printf "$(tput setaf 2)"
			printf "$peer"
			
			printf "$NORMAL"
		printf "\n"
		elif echo $peer | grep 'LAGGED' > /dev/null; then
			printf "$(tput setaf 3)"
			printf "$peer"
			
			printf "$NORMAL"
		printf "\n"
		elif echo $peer | grep 'UNREACHABLE' > /dev/null; then
			printf "$(tput setaf 1)"
			printf "$peer"
			
			printf "$NORMAL"
		printf "\n"
		elif echo $peer | grep 'UNKNOWN' > /dev/null; then
			printf "$(tput setaf 1)"
			printf "$peer"
			
			printf "$NORMAL"
		printf "\n"
		elif echo $peer | grep 'Unmonitored' > /dev/null; then
			if echo $peer | grep 'sip peers' > /dev/null; then
				printf "\r"
			else
				printf "$peer"
		printf "\n"
			fi
		fi
	done < /tmp/peer.tmp
	printf "\n"
	
	printf '\n %-15s %-40s %s\n' "$MAGENTA#####" "Calls activity and used channels" "#####$NORMAL"
	
	printf '  %-*.*s\n' $col3 $col3 "Active calls: $(/usr/sbin/asterisk -rx 'core show channels' | grep 'active' | grep 'calls' | cut -d' ' -f1)"
	printf '  %-*.*s\n' $col3 $col3 "Active channels: $(/usr/sbin/asterisk -rx 'core show channels' | grep 'active' | grep 'channels' | cut -d' ' -f1)"
	printf '  %-*.*s\n' $col3 $col3 "Total calls: $(/usr/sbin/asterisk -rx 'core show channels' | grep 'processed' | cut -d' ' -f1)"
	printf '\n'
}


case "$1" in
	-install)
		nms_install
		;;
	-update)
		nms_update
		;;
	-check)
		nms_check
		;;
	-split)
		tmux new-window -a -n Nixxis
		tmux new-session -d -s Nixxis $3
		tmux selectp -t Nixxis:0
		tmux splitw $2 "tail -f /var/log/nixxis/installation.log"
		tmux selectl even-vertical
		tmux attach -t Nixxis
		;;
-full)
		nms_install
		#nms_config
		nms_check
		;;
	*)
	printf '\n%s\n ' "$CYAN======== Nixxis Media Server: Installation script help =========$NORMAL"
	printf '\n%s\n ' "$ORANGE $0 -install$NORMAL"
	printf ' %s\n ' " Perform the installation of Media Server"
	##printf '\n%s\n ' "$ORANGE $0 -update$NORMAL"
	##printf ' %s\n ' " Allow to update to the version of Nixxis Dialplans"
	printf '\n%s\n ' "$ORANGE $0 -check$NORMAL"
	printf ' %s\n ' " Allow to check the installation, configuration and system constant"
		;;
esac

