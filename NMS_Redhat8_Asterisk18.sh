#!/bin/bash
# ----------------------------------------------------------------------#
# [Author]       Nixxis Support Team/Nixxis Indian Ocean by SMARCQ      #
# [Company]      Nixxis Belgium S.P.R.L.                                #
# [Title]        Nixxis Media Server Installation Script                #
# [Description]  This script is a tool which allow installation and     #
#                maintenance in a super easy way. Installation become   #
#                as simple as typing the name of the script followed    #
#                by a command and then look back when the job is done   #
# ----------------------------------------------------------------------#
# [Prerequisities]  Must be run as root on RedHat 8                     #
# [Usage]           * Give execution right to the script                #
#                   * Run the script with action as argument            #
#                       - Install will install Nixxis MS                #
#                       - Config is a wizard to config sip connection   #
#                       - Check components health                       #
# ----------------------------------------------------------------------#
# [File Version]        3.0                                             #
# [Nixxis Version]      3.0                                             #
# [Asterisk Version]    11.25                                           #
# ----------------------------------------------------------------------#
# [Last Update]         11 Juin 2023							        #
#                       Updated to Nixxis Contact Suite 3.0             #
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
NixxisUri="http://update.nixxis.net/v3.0/Install.3.0.0.zip"
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
	
	# Check if os is supported RedHat.
	if rpm -qa \*-release | grep -Ei "RedHat" | cut -d"-" -f3 | grep -iho "8" > /dev/null 2>&1; then 
			osversion="8"
			if uname -m | grep -q "x86_64" > /dev/null 2>&1; then
				osarch="64"
				echo "RedHat 8 64bit Installed" >> /var/log/nixxis/installation.log
			else
				echo "RedHat 8 32bit Installed" >> /var/log/nixxis/installation.log
			fi
			
	else 
			printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "This installation of Nixxis is for RedHat 8 only"
			printf '\n\n %-25s %s\n ' " " "$RED This installation of Nixxis is for RedHat 8 only $NORMAL" >> /var/log/nixxis/installation.log
			exit
	fi
	printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "OS RedHat $osversion installed"
	
	
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
	if systemctl status  ntpd.service | grep "Loaded: " | grep -q "loaded" > /dev/null 2>&1; then
		if systemctl status  ntpd.service | grep "Active: " | grep -q "inactive" > /dev/null 2>&1; then
		
			systemctl enable ntpd.service >> /var/log/nixxis/installation.log 2>&1
			ntpdate pool.ntp.org >> /var/log/nixxis/installation.log 2>&1
			systemctl start ntpd.service >> /var/log/nixxis/installation.log 2>&1
								
			if systemctl status  ntpd.service | grep "Active: " | grep -q "active" > /dev/null 2>&1; then
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
	yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
	yum -y install https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-8.noarch.rpm
	if yum -y install epel-release >> /var/log/nixxis/installation.log 2>&1; then
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$GREEN [ ✓ Ok ] $NORMAL" 
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Adding EPEL repository" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	
	# updating installation
	printf '%-*s %s\r ' $col "Updating yum" "$NORMAL [ ... ] $NORMAL"
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
	pkgs=( "git.x86_64" "net-tools" "gcc gcc-c++" "pjproject" "libxml2-devel" "ncurses-devel" "dialog" "curl" "curl-devel" "whois.x86_64" "libuuid-devel" "ntp" "nano" "jansson.x86_64")
for pkg in ${pkgs[*]}; do
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
	else
		if yum install -y net-snmp  >> /var/log/nixxis/installation.log 2>&1; then
				printf '%-*s %s\n ' $col "Installing snmp" "$GREEN [ ✓ Ok ] $NORMAL"
				printf '%-*s %s\n ' $col "Installing snmp" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
		else
				printf '%-*s %s\n ' $col "Installing snmp" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
		fi
	fi
	service snmpd start > /dev/null 2>&1
# additionnal packages 
	printf '%-15s %s\n ' "$ORANGE-----" "additionnal packages$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "additionnal packages$NORMAL" >> /var/log/nixxis/installation.log
	yum -y install https://vault.centos.org/centos/8/PowerTools/x86_64/os/Packages/libedit-devel-3.1-23.20170329cvs.el8.x86_64.rpm
	yum -y install https://rpmfind.net/linux/dag/redhat/el3/en/x86_64/dag/RPMS/libedit-20090923-3.0_1.el3.rf.x86_64.rpm
	pkgs=( "libuuid-devel" "kernel-devel" "bison" "openssl-devel" "libtermcap-devel" "sox" "wireshark" "ncurses-devel")
		
	for pkg in ${pkgs[*]}; do
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
# option packages (connections DB)
	printf '%-15s %s\n ' "$ORANGE-----" "option packages (connections DB)$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "option packages (connections DB)$NORMAL" >> /var/log/nixxis/installation.log
	pkgs=( "wget" "mysql-devel" "sqlite-devel" "libtool-ltdl-devel" "samba-client" "perl-libwww-perl" "mlocate" "ntp" "rsync" "svn")
for pkg in ${pkgs[*]}; do
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
	
	#installing json library
	printf '%-15s %s\n ' "$ORANGE-----" "JSON library$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "JSON library$NORMAL" >> /var/log/nixxis/installation.log
	
	
	#yum install -y libuuid-devel ntp nano >> /var/log/nixxis/installation.log 2>&1
	yum install https://rpmfind.net/linux/centos/8-stream/AppStream/x86_64/os/Packages/jansson-devel-2.11-3.el8.x86_64.rpm
	#installing PjProject
	printf '%-*s %s\r ' $col "Installing PjProject" "$NORMAL [ ... ] $NORMAL"
	printf '%-*s %s\r ' $col "Installing PjProject" "$NORMAL [ ... ] $NORMAL" >> /var/log/nixxis/installation.log
	cd /usr/src/ >> /var/log/nixxis/installation.log 2>&1
	git clone https://github.com/pjsip/pjproject.git
	cd /usr/src/pjproject >> /var/log/nixxis/installation.log 2>&1
	./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr >> /var/log/nixxis/installation.log 2>&1
	make dep >> /var/log/nixxis/installation.log 2>&1
	make >> /var/log/nixxis/installation.log 2>&1
	make install >> /var/log/nixxis/installation.log 2>&1
	ldconfig >> /var/log/nixxis/installation.log 2>&1

	printf '%-*s %s\n ' $col "Installing PjProject" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Installing PjProject" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	
	yum -y install js-devel	>> /var/log/nixxis/installation.log 2>&1
	wget http://github.com/micha/jsawk/raw/master/jsawk >> /var/log/nixxis/installation.log 2>&1
	chmod 755 jsawk && mv jsawk /usr/sbin/ >> /var/log/nixxis/installation.log 2>&1
	
	#installing MPEG Audio
	printf '%-15s %s\n ' "$ORANGE-----" "MPEG Audio Player & decoder library$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "MPEG Audio Player & decoder library$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Installing mpg123" "$NORMAL [ ... ] $NORMAL"
	cd /usr/src >> /var/log/nixxis/installation.log 2>&1
	wget http://sourceforge.net/projects/mpg123/files/mpg123/1.24.0/mpg123-1.24.0.tar.bz2 >> /var/log/nixxis/installation.log 2>&1
	tar -xjvf mpg123-1.24.0.tar.bz2 >> /var/log/nixxis/installation.log 2>&1
	cd mpg123-1.24.0 >> /var/log/nixxis/installation.log 2>&1
	./configure >> /var/log/nixxis/installation.log 2>&1 && make -s >> /var/log/nixxis/installation.log 2>&1 && make -s install >> /var/log/nixxis/installation.log 2>&1
updatedb >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Installing mpg123" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Installing mpg123" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Lame MP3 encoder & Lighttpd web-server
	printf '%-15s %s\n ' "$ORANGE-----" "Installing Lighttpd web-server$NORMAL"
	printf '%-15s %s\n ' "$ORANGE-----" "Installing Lighttpd web-server$NORMAL" >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Installing lighttpd lame" "$NORMAL [ ... ] $NORMAL"
	cd /usr/src
	if rpm -qa | grep  lighttpd > /dev/null 2>&1 -a rpm -qa | grep  lame > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Installing lighttpd" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Installing lighttpd" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	else
				
		yum install -y lighttpd  >> /var/log/nixxis/installation.log 2>&1
		if rpm -qa | grep  lighttpd > /dev/null 2>&1 ; then
			printf '%-*s %s\n ' $col "Installing lighttpd" "$GREEN [ ✓ Ok ] $NORMAL" 
			printf '%-*s %s\n ' $col "Installing lighttpd" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
			#contrib/scripts/get_mp3_source.sh >> /var/log/nixxis/installation.log
		else
			printf '%-*s %s\n ' $col "Installing lighttpd" "$RED [ ✗ Fail ] $NORMAL"
			echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
			((failcount++))
		fi 
	fi
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
# IVR and scripting related packages
	printf '%-15s %s\n ' "$ORANGE-----" "Installing IVR$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Installing IVR$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Installing IVR" "$NORMAL [ ... ] $NORMAL"
	if rpm -qa | grep  php-cli > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Installing IVR" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Installing IVR" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		if yum install -y php-cli  >> /var/log/nixxis/installation.log 2>&1; then
				printf '%-*s %s\n ' $col "Installing IVR" "$GREEN [ ✓ Ok ] $NORMAL" 
				printf '%-*s %s\n ' $col "Installing IVR" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
		else
				printf '%-*s %s\n ' $col "Installing IVR" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
		fi
	fi
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
# FTP server + adaptation config + autostart
	printf '%-15s %s\n ' "$ORANGE-----" "Installing & configuring FTP server$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Installing & configuring FTP server$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Installing FTP server" "$NORMAL [ ... ] $NORMAL"
	if rpm -qa | grep  vsftpd > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Installing FTP server" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Installing FTP server" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		if yum install -y vsftpd  >> /var/log/nixxis/installation.log 2>&1; then
				printf '%-*s %s\n ' $col "Installing FTP server" "$GREEN [ ✓ Ok ] $NORMAL"
				printf '%-*s %s\n ' $col "Installing FTP server" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
		else
				printf '%-*s %s\n ' $col "Installing FTP server" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ########################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
		fi
	fi
printf '%-*s %s\r ' $col "Editing /etc/vsftpd/vsftpd.conf" "$NORMAL [ ... ] $NORMAL"
	sed -i 's|.*anonymous_enable=.*|anonymous_enable=NO|' /etc/vsftpd/vsftpd.conf
	sed -i 's|.*local_enable=.*|local_enable=YES|' /etc/vsftpd/vsftpd.conf 
	sed -i 's|.*write_enable=.*|write_enable=YES|' /etc/vsftpd/vsftpd.conf 
	sed -i 'N;s|\# (default follows)\n\#chroot_list_file=/etc/vsftpd/chroot_list|\n\n\#chroot_list_file=/etc/vsftpd/chroot_list\nchroot_local_user=YES\n\n|' /etc/vsftpd/vsftpd.conf
	sed -i 's|.*chroot_local_user=.*|chroot_local_user=YES|' /etc/vsftpd/vsftpd.conf 
echo 'reverse_lookup_enable=NO' >> /etc/vsftpd/vsftpd.conf 
printf '%-*s %s\n ' $col "Editing /etc/vsftpd/vsftpd.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/vsftpd/vsftpd.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
chkconfig vsftpd on >> /var/log/nixxis/installation.log 2>&1
printf '%-*s %s\n ' $col "Starting vsftpd" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Starting vsftpd" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	
	
	
	#Configuring Installation
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Configuring installation script" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Configuring installation script" "#####$NORMAL" >> /var/log/nixxis/installation.log
	
	printf '%-*s %s\n ' $col "Check if config file exist" "$NORMAL [  Done  ] $NORMAL"
	printf '%-*s %s\n ' $col "Check if config file exist" "$NORMAL [  Done  ] $NORMAL" >> /var/log/nixxis/installation.log
	
	if [ -f nmsConfig.json ] ; then
		printf '\n\n %-25s %s\n ' " " "$ORANGE ---  Config file exist !   --- $NORMAL"
		printf '\n\n %-25s %s\n ' " " "$ORANGE ---  Config file exist !   --- $NORMAL" >> /var/log/nixxis/installation.log
		printf '\n\t A config file alreay exist.'
		read -p 'Do you want to use this configuration ? [Y/n]' Flag
		if [ "$Flag" != "N" ] && [ "$Flag" != "n" ] && [ "$Flag" != "no" ] && [ "$Flag" != "No" ] ; then
			printf '\n '
			doconfig="false"
				
			printf '%-*s %s\n\n ' $col "Load config from file" "$NORMAL [  Done  ] $NORMAL"
			printf '%-*s %s\n\n ' $col "Load config from file" "$NORMAL [  Done  ] $NORMAL" >> /var/log/nixxis/installation.log
			
			config_core_appserver=$(cat nmsConfig.json | jsawk 'return this.core.appserver')
			printf '%-*s %s\n ' 40 "Connected to AppServer : " "$CYAN $config_core_appserver $NORMAL"
			printf '%-*s %s\n ' 40 "Connected to AppServer : " "$CYAN $config_core_appserver $NORMAL" >> /var/log/nixxis/installation.log
			config_asterisk_lang=$(cat nmsConfig.json | jsawk 'return this.asterisk.lang')
			config_asterisk_langraw=$(echo -ne "$config_asterisk_lang" | tr ',' \\n)
			printf '%-*s %s\n ' 40 "Activated language : " "$CYAN $config_asterisk_lang $NORMAL"
			printf '%-*s %s\n ' 40 "Activated language : " "$CYAN $config_asterisk_lang $NORMAL" >> /var/log/nixxis/installation.log
			config_asterisk_codec=$(cat nmsConfig.json | jsawk 'return this.asterisk.codec')
			config_asterisk_codecraw=$(echo -ne "$config_asterisk_codec" | tr ',' \\n)
			printf '%-*s %s\n ' 40 "Activated codec : " "$CYAN $config_asterisk_codec $NORMAL"
			printf '%-*s %s\n ' 40 "Activated codec : " "$CYAN $config_asterisk_codec $NORMAL" >> /var/log/nixxis/installation.log
			config_asterisk_patch_AEOH=$(cat nmsConfig.json | jsawk 'return this.asterisk.patch.AEOH')
			if [ "$config_asterisk_patch_AEOH" = "true" ] ; then
				printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$GREEN $config_asterisk_patch_AEOH $NORMAL"
				printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$GREEN $config_asterisk_patch_AEOH $NORMAL" >> /var/log/nixxis/installation.log
			else                        
				printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$RED $config_asterisk_patch_AEOH $NORMAL"
				printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$RED $config_asterisk_patch_AEOH $NORMAL" >> /var/log/nixxis/installation.log
			fi
			config_sip_providerlenght=$(($(cat nmsConfig.json | jsawk 'return this.sip.providerlenght') - 1))
			z=-1
			while [ "$z" -lt "$config_sip_providerlenght" ] ; do
				z=$(($z + 1))
				config_sip_provider_name[$z]=$(cat nmsConfig.json | jsawk 'return this.sip.provider['$z'].name')
				config_sip_provider_host[$z]=$(cat nmsConfig.json | jsawk 'return this.sip.provider['$z'].host')
				config_sip_provider_username[$z]=$(cat nmsConfig.json | jsawk 'return this.sip.provider['$z'].username')
				config_sip_provider_password[$z]=$(cat nmsConfig.json | jsawk 'return this.sip.provider['$z'].password')
				
				printf '%-*s %s\n ' 40 "Provider will be setup : " "$CYAN ${config_sip_provider_name[$z]} $NORMAL"
				printf '%-*s %s\n ' 40 "Provider will be setup : " "$CYAN ${config_sip_provider_name[$z]} $NORMAL" >> /var/log/nixxis/installation.log
			done
			
			config_asterisk_menuselect="menuselect/menuselect --disable BUILD_NATIVE --enable func_curl --disable-category MENUSELECT_CORE_SOUNDS --disable-category MENUSELECT_MOH --disable-category MENUSELECT_EXTRA_SOUNDS"
			config_core_lang_NL="false"
			for x in $config_asterisk_langraw; do
				if [ "$x" = "NL" ] ; then
					config_core_lang_NL="true"
				else
					for y in $config_asterisk_codecraw; do
						config_asterisk_menuselect="$config_asterisk_menuselect --enable CORE-SOUNDS-${x}-${y}"
					done
				fi
			done
			for y in $config_asterisk_codecraw; do
				config_asterisk_menuselect="$config_asterisk_menuselect --enable MOH-OPSOUND-${y}"
			done
			for x in $config_asterisk_langraw; do
				if [ "$x" != "NL" ] ; then
					for y in $config_asterisk_codecraw; do
						config_asterisk_menuselect="$config_asterisk_menuselect --enable EXTRA-SOUNDS-${x}-${y}"
					done
				fi
			done
config_asterisk_menuselect="$config_asterisk_menuselect menuselect.makeopts >> /var/log/nixxis/installation.log 2>&1"
			
			config_sip_conf_general="[general]\nconstantssrc=yes\ncontext=undefined\nallowoverlap=no\nudpbindaddr=0.0.0.0\ntcpenable=no\ntcpbindaddr=0.0.0.0\ntransport=udp\nsrvlookup=yes\nignoresdpversion=yes\nt1min=500\n\n"
			config_sip_conf_register=" "
			config_sip_conf_appserver="[AppServer]\ntype=friend\ncontext=nixxis\nfromdomain=${config_core_appserver}\nhost=${config_core_appserver}\ndtmfmode=info\ndisallow=all\nallow=alaw\ndirectmedia=no\ncanreinvite=no\nqualify=yes\nnat=no\n;sendrpid=yes\ntrustrpid=yes\nrpid_update=no\n"
			config_sip_conf_provider=" "
			if [ "$config_sip_providerlenght" -gt "0" ] ; then
				z=1
				while [ "$z" -lt "$config_sip_providerlenght" ] ; do
					config_sip_conf_register="${config_sip_conf_register}\n\n;${config_sip_provider_name[$z]} (by install script)\n"
					config_sip_conf_provider="${config_sip_conf_provider}\n\n;${config_sip_provider_name[$z]} (by install script)\n[${config_sip_provider_name[$z]}]\n"
					config_sip_conf_provider="${config_sip_conf_provider}fromdomain=${config_sip_provider_host[$z]}\nhost=${config_sip_provider_host[$z]}\n"
					config_sip_conf_provider="${config_sip_conf_provider}type=friend\nusername=${config_sip_provider_username[$z]}\nfromuser=${config_sip_provider_username[$z]}\n"
					config_sip_conf_register="${config_sip_conf_register}register => ${config_sip_provider_username[$z]}:${config_sip_provider_password[$z]}:${config_sip_provider_username[$z]}@${config_sip_provider_host[$z]}/${config_sip_provider_username[$z]}\n"
					config_sip_conf_provider="${config_sip_conf_provider}secret=${config_sip_provider_password[$z]}\n"
					config_sip_conf_provider="${config_sip_conf_provider}canreinvite=no\ninsecure=invite,port\nqualify=yes\ndisallow=all\nallow=alaw\namaflags=billing\ntrustrpid=yes\nsendrpid=yes\ncontext=nixxis-inbound\naccountcode=default\n\n"
					
					z=$(($z + 1))
				done
			else 
				config_sip_conf_register="\n"
				config_sip_conf_provider="\n\n; Sample Provider\n;[firstcarrier]\n;type=friend\n;username=1234\n;fromuser=1234\n;fromdomain=sip1.nixxis.com\n;secret=4321\n;host=sip1.nixxis.com\n;canreinvite=no\n;insecure=invite,port\n;qualify=yes\n;disallow=all\n;allow=alaw\n;amaflags=billing\n;trustrpid=yes\n;sendrpid=yes\n;context=nixxis-inbound\n;accountcode=default\n\n;force appserver http uri to something else (else, http://${PeerIp}:8088 is used)\n;setvar=NixxisAppServerUri=http://5.6.7.8:8088\n;setvar=BackupCarrier=secondcarrier\n"
			fi
		fi
	fi
	if [ "$doconfig" = "true" ] ; then
		printf '\n '
 		# Some whiptail dialog getting all needed data for menuselect construction
		whiptail --separate-output --fb --clear --title "Asterisk option" --checklist "Select languages for sound packages" 12 40 5 EN " - English" on FR " - French" on  NL " - Dutch" off 3>&1 1>&2 2>/tmp/var
		if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL"
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL" >> /var/log/nixxis/installation.log
			exit 
		fi
		config_asterisk_langraw=$(</tmp/var)
		if [ "$config_asterisk_langraw" = "" ] ; then
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL" 
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL" >> /var/log/nixxis/installation.log
			exit 
		fi
		whiptail --separate-output --fb --clear --title "Asterisk option" --checklist "Select Audio formats for sound packages" 16 40 9 WAV "" on ULAW "G.711 񭬡w, 64kbit/s" off ALAW "G.711 A-law, 64kbit/s" on GSM "" off G729 "G.729 algorithm" on G722 "G.722, 64kbit/s" off SLN16 "" off SIREN7 "" off SIREN14 "" off 3>&1 1>&2 2>/tmp/var
		if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL"
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL" >> /var/log/nixxis/installation.log
			exit 
		fi
		config_asterisk_codecraw=$(</tmp/var)
		if [ "$config_asterisk_codecraw" = "" ] ; then
			printf '\n\n %-25s %s\n ' " " "$RED   No codec selected $NORMAL" 
			printf '\n\n %-25s %s\n ' " " "$RED   No codec selected $NORMAL" >> /var/log/nixxis/installation.log
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL" 
			printf '\n\n %-25s %s\n ' " " "$RED Installation cancelled $NORMAL" >> /var/log/nixxis/installation.log
			exit 
		fi
		
		if [ -f "$ScriptDir/AgiExitOnHangup.patch" ] ;	then
			if (whiptail --title "Patch File Found" --yesno "The patch file for AgiExitOnHangup have been found.\nWould you want to apply it ?\n\n   AGI\n   ---\n    * Add a new channel variable, AGIEXITONHANGUP, which allows\n      Asterisk to behave like it did in Asterisk 1.4 and earlier where the\n      AGI application would exit immediately after a channel hangup is detected." 16 90) then
				config_asterisk_patch_AEOH="true"
			else 
				config_asterisk_patch_AEOH="false"
			fi
		fi
		
		
		whiptail --fb --clear --title "AppServer IP" --inputbox "Please enter your AppServer IP (which is running CrAppServer)" 12 78 ""  3>&1 1>&2 2>/tmp/var
		if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
			echo Cancel
			exit 
		fi
		config_core_appserver=$(</tmp/var)
		if [ "$config_core_appserver" = "" ] ; then
			echo No Select
			exit 
		fi
		
		config_sip_providerlenght=0
		
		config_sip_conf_general="[general]\nconstantssrc=yes\ncontext=undefined\nallowoverlap=no\nudpbindaddr=0.0.0.0\ntcpenable=no\ntcpbindaddr=0.0.0.0\ntransport=udp\nsrvlookup=yes\nignoresdpversion=yes\nt1min=500\n\n"
		config_sip_conf_register=" "
		config_sip_conf_appserver="[AppServer]\ntype=friend\ncontext=nixxis\nfromdomain=${config_core_appserver}\nhost=${config_core_appserver}\ndtmfmode=info\ndisallow=all\nallow=alaw\ndirectmedia=no\ncanreinvite=no\nqualify=yes\nnat=no\n;sendrpid=yes\ntrustrpid=yes\nrpid_update=no\n"
		config_sip_conf_provider=" "
		if (whiptail --fb --clear --title "SIP Account" --yesno "Do you already have a sip account?" 12 40 3>&1 1>&2 2>&3) then
			while true; do
				whiptail --fb --clear --title "SIP Account" --inputbox "Please enter a provider name" 12 40 ""  3>&1 1>&2 2>/tmp/var
				if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
					echo Cancel
					exit 
				fi
				config_sip_provider_name[$config_sip_providerlenght]=$(</tmp/var)
				if [ "$config_sip_provider_name[$config_sip_providerlenght]" = "" ] ; then
					echo No Select
					exit 
				fi
				config_sip_conf_register="${config_sip_conf_register}\n\n;${config_sip_provider_name[$config_sip_providerlenght]} (by install script)\n"
				config_sip_conf_provider="${config_sip_conf_provider}\n\n;${config_sip_provider_name[$config_sip_providerlenght]} (by install script)\n[${config_sip_provider_name[$config_sip_providerlenght]}]\n"
				whiptail --fb --clear --title "SIP Account" --inputbox "Please enter the IP of provider host" 12 40 ""  3>&1 1>&2 2>/tmp/var
				if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
					echo Cancel
					exit 
				fi
				config_sip_provider_host[$config_sip_providerlenght]=$(</tmp/var)
				if [ "$config_sip_provider_host[$config_sip_providerlenght]" = "" ] ; then
					echo No Select
					exit 
				fi
				config_sip_conf_provider="${config_sip_conf_provider}fromdomain=${config_sip_provider_host[$config_sip_providerlenght]}\nhost=${config_sip_provider_host[$config_sip_providerlenght]}\n"
				whiptail --fb --clear --title "SIP Account" --inputbox "Please enter your connection username" 12 40 ""  3>&1 1>&2 2>/tmp/var
				if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
					echo Cancel
				 exit 
				fi
				config_sip_provider_username[$config_sip_providerlenght]=$(</tmp/var)
				if [ "$config_sip_provider_username[$config_sip_providerlenght]" = "" ] ; then
					echo No Select
					exit 
				fi
				config_sip_conf_provider="${config_sip_conf_provider}type=friend\nusername=${config_sip_provider_username[$config_sip_providerlenght]}\nfromuser=${config_sip_provider_username[$config_sip_providerlenght]}\n"
				whiptail --fb --clear --title "SIP Account" --inputbox "Finally please enter your password" 12 40 ""  3>&1 1>&2 2>/tmp/var
				if [ "$?" -eq "1" ] || [ "$?" -eq "255" ] ; then
					echo Cancel
					exit 
				fi
				config_sip_provider_password[$config_sip_providerlenght]=$(</tmp/var)
				if [ "$config_sip_provider_password[$config_sip_providerlenght]" = "" ] ; then
					echo No Select
					exit 
				fi
				config_sip_conf_register="${config_sip_conf_register}register => ${config_sip_provider_username[$config_sip_providerlenght]}:${config_sip_provider_password[$config_sip_providerlenght]}:${config_sip_provider_username[$config_sip_providerlenght]}@${config_sip_provider_host[$config_sip_providerlenght]}/${config_sip_provider_username[$config_sip_providerlenght]}\n"
				config_sip_conf_provider="${config_sip_conf_provider}secret=${config_sip_provider_password[$config_sip_providerlenght]}\n"
				config_sip_conf_provider="${config_sip_conf_provider}canreinvite=no\ninsecure=invite,port\nqualify=yes\ndisallow=all\nallow=alaw\namaflags=billing\ntrustrpid=yes\nsendrpid=yes\ncontext=nixxis-inbound\naccountcode=default\n\n"
		
				whiptail --fb --clear --title "SIP Account" --yesno "Do you want to enter an other SIP Account?" 12 40 3>&1 1>&2 2>&3 || break
				config_sip_providerlenght=$(( $config_sip_providerlenght + 1))
			done
		else
			config_sip_conf_register="\n"
			config_sip_conf_provider="\n\n; Sample Provider\n;[firstcarrier]\n;type=friend\n;username=1234\n;fromuser=1234\n;fromdomain=sip1.nixxis.com\n;secret=4321\n;host=sip1.nixxis.com\n;canreinvite=no\n;insecure=invite,port\n;qualify=yes\n;disallow=all\n;allow=alaw\n;amaflags=billing\n;trustrpid=yes\n;sendrpid=yes\n;context=nixxis-inbound\n;accountcode=default\n\n;force appserver http uri to something else (else, http://${PeerIp}:8088 is used)\n;setvar=NixxisAppServerUri=http://5.6.7.8:8088\n;setvar=BackupCarrier=secondcarrier\n"
		fi
		config_sip_conf_complete="${config_sip_conf_general}${config_sip_conf_register}${config_sip_conf_appserver}${config_sip_conf_provider}\n\n; Sample back office phones\n;[54321]\n;type=friend\n;secret=54321\n;context=nixxis\n;host=dynamic\n;disallow=all\n;allow=alaw\n;sendrpid=yes\n;trustrpid=yes\n;canreinvite=no\n;pickupgoup=1\n;callgroup=1\n;accountcode=default\n;setvar=PROV=firstcarrier"
	
		config_asterisk_menuselect="menuselect/menuselect --disable BUILD_NATIVE --enable func_curl --disable-category config_asterisk_menuselect_CORE_SOUNDS --disable-category config_asterisk_menuselect_MOH --disable-category config_asterisk_menuselect_EXTRA_SOUNDS"
		config_core_lang_NL="false"
		for x in $config_asterisk_langraw; do
			if [ "$x" = "NL" ] ; then
				config_core_lang_NL="true"
			else
				for y in $config_asterisk_codecraw; do
					config_asterisk_menuselect="$config_asterisk_menuselect --enable CORE-SOUNDS-${x}-${y}"
				done
			fi
		done
		for y in $config_asterisk_codecraw; do
			config_asterisk_menuselect="$config_asterisk_menuselect --enable MOH-OPSOUND-${y}"
		done
		for x in $config_asterisk_langraw; do
			if [ "$x" != "NL" ] ; then
				for y in $config_asterisk_codecraw; do
					config_asterisk_menuselect="$config_asterisk_menuselect --enable EXTRA-SOUNDS-${x}-${y}"
				done
			fi
		done
		
		config_asterisk_lang=$(echo -ne "$config_asterisk_langraw" | tr \\n ',')
		config_asterisk_codec=$(echo -ne "$config_asterisk_codecraw" | tr \\n ',')
config_asterisk_menuselect="$config_asterisk_menuselect menuselect.makeopts >> /var/log/nixxis/installation.log 2>&1"
		
		printf '%-*s %s\n\n ' $col "Load config from user imput" "$NORMAL [  Done  ] $NORMAL"
		printf '%-*s %s\n\n ' $col "Load config from user imput" "$NORMAL [  Done  ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\n ' 40 "Connected to AppServer : " "$CYAN $config_core_appserver $NORMAL"
		printf '%-*s %s\n ' 40 "Connected to AppServer : " "$CYAN $config_core_appserver $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\n ' 40 "Activated language : " "$CYAN $config_asterisk_lang $NORMAL"
		printf '%-*s %s\n ' 40 "Activated language : " "$CYAN $config_asterisk_lang $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\n ' 40 "Activated codec : " "$CYAN $config_asterisk_codec $NORMAL"
		printf '%-*s %s\n ' 40 "Activated codec : " "$CYAN $config_asterisk_codec $NORMAL" >> /var/log/nixxis/installation.log
		if [ "$config_asterisk_patch_AEOH" = "true" ] ; then
			printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$GREEN $config_asterisk_patch_AEOH $NORMAL"
			printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$GREEN $config_asterisk_patch_AEOH $NORMAL" >> /var/log/nixxis/installation.log
		else                        
			printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$RED $config_asterisk_patch_AEOH $NORMAL"
			printf '%-*s %s\n ' 40 "AgiExitOnHangup path will be install : " "$RED $config_asterisk_patch_AEOH $NORMAL" >> /var/log/nixxis/installation.log
		fi
		
		echo '{' > nmsConfig.json
		echo '	core: {' >> nmsConfig.json
		echo '		appserver: "'$config_core_appserver'"' >> nmsConfig.json
		echo '	}' >> nmsConfig.json
		echo '	,' >> nmsConfig.json
		echo '	asterisk: {' >> nmsConfig.json
		echo '		lang: "'$config_asterisk_lang'",' >> nmsConfig.json
		echo '		codec: "'$config_asterisk_codec'",' >> nmsConfig.json
		echo '		patch: {' >> nmsConfig.json
		echo '			AEOH: "'$config_asterisk_patch_AEOH'"' >> nmsConfig.json
		echo '		}' >> nmsConfig.json
		echo '	}' >> nmsConfig.json
		echo '	,' >> nmsConfig.json
		echo '	sip: {' >> nmsConfig.json
		echo '		providerlenght: "'$(($config_sip_providerlenght + 1))'",' >> nmsConfig.json
		echo '		provider: [' >> nmsConfig.json
		z=-1
		while [ "$z" -lt "$config_sip_providerlenght" ] ; do
			z=$(($z + 1))
			printf '%-*s %s\n ' 40 "Provider will be setup : " "$CYAN ${config_sip_provider_name[$z]} $NORMAL"
			printf '%-*s %s\n ' 40 "Provider will be setup : " "$CYAN ${config_sip_provider_name[$z]} $NORMAL" >> /var/log/nixxis/installation.log
			echo '			{' >> nmsConfig.json
			echo '				name: "'${config_sip_provider_name[$z]}'",' >> nmsConfig.json
			echo '				host: "'${config_sip_provider_host[$z]}'",' >> nmsConfig.json
			echo '				username: "'${config_sip_provider_username[$z]}'",' >> nmsConfig.json
			echo '				password: "'${config_sip_provider_password[$z]}'"' >> nmsConfig.json
			echo '			}' >> nmsConfig.json
			if [ "$z" -ne "$config_sip_providerlenght" ] ; then
				echo '			,' >> nmsConfig.json
			fi
		done
		echo '		]' >> nmsConfig.json
		echo '	}' >> nmsConfig.json
		echo '}' >> nmsConfig.json
	fi
	
printf '\n %-25s %s\n ' " " "$CYAN======== Installing asterisk =========$NORMAL" 
	printf '\n %-25s %s\n ' " " "$CYAN======== Installing asterisk =========$NORMAL" >> /var/log/nixxis/installation.log
# downloading the packages
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Downloading packages" "#####$NORMAL"  
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Downloading packages" "#####$NORMAL"  >> /var/log/nixxis/installation.log
	mkdir /usr/src/asterisk >> /var/log/nixxis/installation.log 2>&1
	cd /usr/src/asterisk >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\r ' $col "Downloading asterisk" "$NORMAL [ ... ] $NORMAL"
	wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Downloading asterisk" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Downloading asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Uncompressing asterisk" "$NORMAL [ ... ] $NORMAL"
	tar zxvf asterisk-18-current.tar.gz >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Uncompressing asterisk" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Uncompressing asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	
	#skip hardware drivers unless needed
	if [ "$installhardware" = "true" ] ; then
		printf '%-*s %s\r ' $col "Downloading dahdi" "$NORMAL [ ... ] $NORMAL"
		cd /usr/src/ >> /var/log/nixxis/installation.log 2>&1
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
# Applying Patches
	if [ "$config_asterisk_patch_AEOH" = "true" ] ; then
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Applying Patches on Asterisk sources" "#####$NORMAL"  
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Applying Patches on Asterisk sources" "#####$NORMAL"  >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Exit Agi On Hangup Patch" "$NORMAL [ ... ] $NORMAL"
		mv /usr/src/asterisk/asterisk-18.* /usr/src/asterisk/asterisk/
		pushd /usr/src/asterisk/asterisk >> /var/log/nixxis/installation.log 2>&1
		patch -p2 < "$ScriptDir/AgiExitOnHangup.patch" >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Exit Agi On Hangup Patch" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Exit Agi On Hangup Patch" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
	
# Downloading and installing hardware/IAX2 support drivers
	if [ "$installhardware" = "true" ] ; then
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing hardware/IAX2 support drivers" "#####$NORMAL" 
		printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing hardware/IAX2 support drivers" "#####$NORMAL" >> /var/log/nixxis/installation.log
		
		printf '%-15s %s\n ' "$ORANGE-----" "Installing Dahdi$NORMAL" 
		printf '%-15s %s\n ' "$ORANGE-----" "Installing Dahdi$NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Building dahdi" "$NORMAL [ ... ] $NORMAL"
		pushd /usr/src/asterisk/dahdi-linux-complete*/  >> /var/log/nixxis/installation.log 2>&1
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
		pushd /usr/src/asterisk/libpri-1.4*/ >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building libpri (make clean)" "$NORMAL [ ... ] $NORMAL"
		make clean >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building libpri (make)" "$NORMAL [ ... ] $NORMAL"
		make >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\r ' $col "Building libpri (make install)" "$NORMAL [ ... ] $NORMAL"
		make install >> /var/log/nixxis/installation.log 2>&1
		printf '%-*s %s\n ' $col "Building libpri" "$GREEN [ Done ] $NORMAL" 
		printf '%-*s %s\n ' $col "Building libpri" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	fi
printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing asterisk" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing asterisk" "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-15s %s\n ' "$ORANGE-----" "Installing asterisk $NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Installing asterisk $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Execute ./configure./configure" "$NORMAL [ ... ] $NORMAL"
	mv /usr/src/asterisk/asterisk-18.* /usr/src/asterisk/asterisk/
	pushd /usr/src/asterisk/asterisk >> /var/log/nixxis/installation.log 2>&1
	./contrib/scripts/install_prereq install >> /var/log/nixxis/installation.log 2>&1
	./configure --libdir=/usr/lib64 --without-pjproject-bundled --with-jansson-bundled >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Execute ./configure" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Execute ./configure" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Building asterisk (make menuselect)" "$NORMAL [ ... ] $NORMAL"
	make menuselect.makeopts >> /var/log/nixxis/installation.log 2>&1
	$config_asterisk_menuselect
printf '%-*s %s\r ' $col "Building asterisk (make)" "$NORMAL [ ... ] $NORMAL"
	make >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\r ' $col "Building asterisk (make install)" "$NORMAL [ ... ] $NORMAL"
	make install >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Building asterisk" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Building asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Creating config files" "$NORMAL [ ... ] $NORMAL"
	make samples >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating config files" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Creating config files" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
	ldconfig >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\r ' $col "Checking Installation" "$NORMAL [ ... ] $NORMAL"
	if service asterisk status > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Checking Installation" "$GREEN [ ✓ Ok ] $NORMAL" 
		printf '%-*s %s\n ' $col "Checking Installation" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		printf '%-*s %s\n ' $col "Checking Installation" "$RED [ ✗ Fail ] $NORMAL" 
		printf '%-*s %s\n ' $col "Checking Installation" "$RED [ ✗ Fail ] $NORMAL" >> /var/log/nixxis/installation.log
		printf ' %-*s %s\r ' $col " Starting Asterisk" "$NORMAL [ ... ] $NORMAL"
		service asterisk start >> /var/log/nixxis/installation.log 2>&1
		printf ' %-*s %s\n ' $col " Starting Asterisk" "$GREEN [ Done ] $NORMAL" 
		printf ' %-*s %s\n ' $col " Starting Asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Checking Installation (2)" "$NORMAL [ ... ] $NORMAL"
	   if service asterisk status > /dev/null 2>&1; then
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
			read -p 'Do you want to continue anyway ? [y/N]' Flag
			if [ "$Flag" != "Y" ] && [ "$Flag" != "y" ] && [ "$Flag" != "Yes" ] && [ "$Flag" != "yes" ] ; then
				exit
			fi
			printf '\n '
		fi
	fi
if [ "$config_core_lang_NL" = "true" ] ; then
		printf '%-15s %s\n ' "$ORANGE[EXTRA]" "Installing Dutch languages patch$NORMAL" 
		printf '%-15s %s\n ' "$ORANGE[EXTRA]" "Installing Dutch languages patch$NORMAL" >> /var/log/nixxis/installation.log
		printf '%-*s %s\r ' $col "Downloading Dutch languages patch" "$NORMAL [ ... ] $NORMAL"
		mkdir -p /var/lib/astek/sounds/nl/ >> /var/log/nixxis/installation.log 2>&1
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
	wget -O NixxisInstall.zip $NixxisUri --user install --password qR4Eqkuz >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Downloading Nixxis pack" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Downloading Nixxis pack" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# unpacking
	printf '%-*s %s\r ' $col "Unpacking Nixxis pack" "$NORMAL [ ... ] $NORMAL" 
	yum install -y unzip >> /var/log/nixxis/installation.log 2>&1
	unzip -o NixxisInstall.zip -d ./nixxis >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Unpacking Nixxis pack" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Unpacking Nixxis pack" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Installing Nixxis Asterisk configuration files
	printf '%-*s %s\r ' $col "Placing Nixxis pack elements" "$NORMAL [ ... ] $NORMAL"
	pushd /usr/src/asterisk/nixxis/MediaServer/ >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/etc/* /etc >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/usr/* /usr >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/var/* /var >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/MediaServer/srv/* /srv >> /var/log/nixxis/installation.log 2>&1
	touch /etc/asterisk/custom.conf >> /var/log/nixxis/installation.log 2>&1
	mkdir /etc/asterisk/nixxis/custom >> /var/log/nixxis/installation.log 2>&1
	touch /etc/asterisk/nixxis/custom/custom.conf >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Placing Nixxis pack elements" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Placing Nixxis pack elements" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "asterisk Configuration" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "asterisk Configuration" "#####$NORMAL" >> /var/log/nixxis/installation.log
#Creating IVR and Recording users
	printf '%-15s %s\n ' "$ORANGE-----" "Creating users$NORMAL" 
	printf '%-15s %s\n ' "$ORANGE-----" "Creating users$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Creating User sounds" "$NORMAL [ ... ] $NORMAL" 
	adduser sounds >> /var/log/nixxis/installation.log 2>&1
	echo -ne "${pbxsound}\n${pbxsound}" | passwd sounds >> /var/log/nixxis/installation.log 2>&1
	chmod 777 /home/sounds >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating User sounds (password: ${pbxsound})" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Creating User sounds (password: ${pbxsound})" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Creating User recording" "$NORMAL [ ... ] $NORMAL"
	adduser recording >> /var/log/nixxis/installation.log 2>&1
	echo -ne "${pbxrecor}\n${pbxrecor}" | passwd recording >> /var/log/nixxis/installation.log 2>&1
	chmod 777 /home/recording >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating User recording (password: ${pbxrecor})" "$GREEN [ Done ] $NORMAL"
	printf '%-*s %s\n ' $col "Creating User recording (password: ${pbxrecor})" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Web-server installation and configuration
printf '%-15s %s\n ' "$ORANGE-----" "Configuring web-server$NORMAL"  
	printf '%-15s %s\n ' "$ORANGE-----" "Configuring web-server$NORMAL"  >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing right" "$NORMAL [ ... ] $NORMAL" 
	chmod a+x /srv/www/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	chgrp recording /var/log/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	chmod g+w /var/log/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Editing /etc/lighttpd/lighttpd.conf" "$NORMAL [ ... ] $NORMAL" 
	sed -i 's|.*server.username  = "lighttpd".*|server.username  = "recording"|' /etc/lighttpd/lighttpd.conf
	sed -i 's|.*server.groupname = "lighttpd".*|server.groupname = "recording"|' /etc/lighttpd/lighttpd.conf
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Stopping lighttpd" "$NORMAL [ ... ] $NORMAL" 
	service lighttpd stop >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Editing right for recording user" "$NORMAL [ ... ] $NORMAL" 
	chown recording:recording /var/log/lighttpd/ >> /var/log/nixxis/installation.log 2>&1
	chown recording:recording /var/log/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	chmod 777 /var/log/* >> /var/log/nixxis/installation.log 2>&1
	chown recording:recording /srv/www/lighttpd >> /var/log/nixxis/installation.log 2>&1
	chown recording:recording /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	chmod 777  /srv/www/lighttpd/* >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing right" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Starting lighttpd" "$NORMAL [ ... ] $NORMAL" 
	chkconfig lighttpd on >> /var/log/nixxis/installation.log 2>&1
	service lighttpd start >> /var/log/nixxis/installation.log 2>&1
	service lighttpd stop >> /var/log/nixxis/installation.log 2>&1
	service lighttpd restart >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Starting lighttpd" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Starting lighttpd" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Editing /etc/lighttpd/lighttpd.conf" "$NORMAL [ ... ] $NORMAL"  
	cd /etc/asterisk >> /var/log/nixxis/installation.log 2>&1
	cp -rf sip_sample.conf sip.conf >> /var/log/nixxis/installation.log 2>&1
	cp -rf extensions_sample.conf extensions.conf >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/lighttpd.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/lighttpd/lighttpd.conf" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
# Adapting config files
	printf '%-15s %s\n ' "$ORANGE-----" "Editing Configuration files$NORMAL"
	printf '%-15s %s\n ' "$ORANGE-----" "Editing Configuration files$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing /etc/asterisk/manager.conf" "$NORMAL [ ... ] $NORMAL" 
	echo -e '\n[nixxis]' >> /etc/asterisk/manager.conf
	echo 'secret=nixxis00' >> /etc/asterisk/manager.conf
	echo 'read = system,call,log,verbose,command,agent,user,config' >> /etc/asterisk/manager.conf
	echo 'write = system,call,log,verbose,command,agent,user,config' >> /etc/asterisk/manager.conf
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/manager.conf" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/manager.conf" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
# fail2ban installation
	printf '%-15s %s\n ' "$ORANGE-----" "Installing & configuring Fail2Ban$NORMAL"
	printf '%-15s %s\n ' "$ORANGE-----" "Installing & configuring Fail2Ban$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Installing Fail2Ban" "$NORMAL [ ... ] $NORMAL"
	if rpm -qa | grep  fail2ban > /dev/null 2>&1; then
		printf '%-*s %s\n ' $col "Installing Fail2Ban" "$NORMAL [ Nothing To Do ] $NORMAL" 
		printf '%-*s %s\n ' $col "Installing Fail2Ban" "$NORMAL [ Nothing To Do ] $NORMAL" >> /var/log/nixxis/installation.log
	else
		if yum install -y fail2ban >> /var/log/nixxis/installation.log 2>&1; then
				printf '%-*s %s\n ' $col "Installing Fail2Ban" "$GREEN [ ✓ Ok ] $NORMAL"
				printf '%-*s %s\n ' $col "Installing Fail2Ban" "$GREEN [ ✓ Ok ] $NORMAL" >> /var/log/nixxis/installation.log
		else
				printf '%-*s %s\n ' $col "Installing Fail2Ban" "$RED [ ✗ Fail ] $NORMAL"
				echo -ne " $RED ####################################################### [ ✗ Fail ] $NORMAL \n" >> /var/log/nixxis/installation.log 2>&1
				((failcount++))
		fi
	fi
printf '%-*s %s\r ' $col "Creating /etc/fail2ban/jail.local" "$NORMAL [ ... ] $NORMAL" 
	cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Creating /etc/fail2ban/jail.local" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Creating /etc/fail2ban/jail.local" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Automatically start Asterisk on server boot
	#####################################TO CHECK THE FOLLOWING ----------------> 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Setup start on wakeup" "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Setup start on wakeup" "#####$NORMAL" >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Copying files" "$NORMAL [ ... ] $NORMAL" 
	cp -rf /usr/src/asterisk/asterisk/contrib/init.d/rc.redhat.asterisk /etc/init.d/asterisk >> /var/log/nixxis/installation.log 2>&1
	chkconfig asterisk on >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Copying files" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Copying files" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Editing /etc/init.d/asterisk" "$NORMAL [ ... ] $NORMAL" 
	sed -i 's|.*AST_SBIN=__ASTERISK_SBIN_DIR__$|AST_SBIN=/usr/sbin|' /etc/init.d/asterisk
	printf '%-*s %s\n ' $col "Editing /etc/init.d/asterisk" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/init.d/asterisk" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
printf '%-*s %s\r ' $col "Starting asterisk" "$NORMAL [ ... ] $NORMAL" 
	service asterisk start >> /var/log/nixxis/installation.log 2>&1
	service asterisk stop  >> /var/log/nixxis/installation.log 2>&1
	service asterisk restart >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Starting asterisk" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Starting asterisk" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# Installing Nixxis V2 related options 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing Nixxis V2 related options " "#####$NORMAL" 
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installing Nixxis V2 related options " "#####$NORMAL" >> /var/log/nixxis/installation.log
	printf '%-*s %s\r ' $col "Editing Nixxis files" "$NORMAL [ ... ] $NORMAL" 
	touch /etc/asterisk/musiconhold_nixxis.conf >> /var/log/nixxis/installation.log 2>&1
	chmod 775 /etc/asterisk/musiconhold_nixxis.conf
	chown sounds:sounds /etc/asterisk/musiconhold_nixxis.conf >> /var/log/nixxis/installation.log 2>&1
sed -i 'N;s|directory=/var/lib/asterisk/moh\n;$|directory=/var/lib/asterisk/moh\n\#include \"musiconhold_nixxis.conf\"\n|' /etc/asterisk/musiconhold.conf
	printf '%-*s %s\n ' $col "Editing Nixxis files" "$GREEN [ Done ] $NORMAL"  
	printf '%-*s %s\n ' $col "Editing Nixxis files" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# /etc/asterisk/modules.conf
	printf '%-*s %s\r ' $col "Editing /etc/asterisk/modules.conf" "$NORMAL [ ... ] $NORMAL" 
	sed -i 's|.*preload => res_odbc.so$|preload => res_odbc.so|' /etc/asterisk/modules.conf
	sed -i 's|.*preload => res_config_odbc.so$|preload => res_config_odbc.so|' /etc/asterisk/modules.conf
	sed -i 's/noload = chan_sip.so/load = chan_sip.so/' /etc/asterisk/modules.conf
	echo -e 'noload => res_pjsip.so' >> /etc/asterisk/modules.conf
	echo -e 'noload => res_config_ldap.so' >> /etc/asterisk/modules.conf
	echo -e 'noload => res_config_pgsql.so' >> /etc/asterisk/modules.conf
	systemctl restart asterisk.service >> /var/log/nixxis/installation.log
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/modules.conf" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing /etc/asterisk/modules.conf" "$GREEN [ Done ] $NORMAL" >> /var/log/nixxis/installation.log
# CLI> module reload res_odbc.so
	asterisk -rx "module reload res_odbc.so" >> /var/log/nixxis/installation.log 2>&1
# SuDo manipulation
	printf '%-*s %s\r ' $col "Editing Sudoers" "$NORMAL [ ... ] $NORMAL" 
	sed -i 'N;s|\## Command Aliases\n\## These are groups of related commands\...|\## Command Aliases\n\## Asterisk\nCmnd\_Alias ASTERISK = \/usr\/sbin\/asterisk, /usr/bin/perl\n|' /etc/sudoers
	sed -i 's|^Defaults    requiretty$|\#Defaults    requiretty\n|' /etc/sudoers
	echo -e 'recording  ALL= NOPASSWD: ASTERISK' >> /etc/sudoers
	printf '%-*s %s\n ' $col "Editing Sudoers" "$GREEN [ Done ] $NORMAL" 
	printf '%-*s %s\n ' $col "Editing Sudoers" "$GREEN [ Done ] $NORMAL"  >> /var/log/nixxis/installation.log
# Setup of sound file synchronization 
	printf '%-*s %s\r ' $col "Creating shared directory" "$NORMAL [ ... ] $NORMAL" 
	mkdir /home/soundsv2share >> /root/Nixxis-configuration.log 2>&1
	mkdir /home/soundsv2 >> /root/Nixxis-configuration.log 2>&1
chown sounds:sounds /home/soundsv2  >> /root/Nixxis-configuration.log 2>&1
	printf '%-*s %s\n ' $col "Creating shared directory" "$GREEN [ Done ] $NORMAL"
printf '%-*s %s\r ' $col "Mounting shared directory" "$NORMAL [ ... ] $NORMAL" 
	echo -e "//${config_core_appserver}/HomeSounds /home/soundsv2share cifs username=sounds,password=${appsound},_netdev 0 0" >> /etc/fstab
	mount /home/soundsv2share/ >> /root/Nixxis-configuration.log 2>&1
	printf '%-*s %s\n ' $col "Mounting shared directory" "$GREEN [ Done ] $NORMAL"
	
	# Setup Sip.conf
	printf '%-*s %s\r ' $col "Overiding Sip.conf" "$NORMAL [ ... ] $NORMAL" 
	echo -ne $config_sip_conf_complete > /etc/asterisk/sip.conf
	printf '%-*s %s\n ' $col "Overiding Sip.conf" "$GREEN [ Done ] $NORMAL"
	
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installation completed" "#####$NORMAL"
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Installation completed" "#####$NORMAL" >> /var/log/nixxis/installation.log
printf '\n\n %-25s %s\n ' " " "$CYAN ---  Congratulations!  --- $NORMAL" 
	printf '\n\n %-25s %s\n ' " " "$CYAN ---  Congratulations!  --- $NORMAL" >> /var/log/nixxis/installation.log
	printf '\n\t You just finish the installation of your Nixxis MediaServer. '
	if [ "$failcount" -gt "0" ]	; then
		printf "\n\t $RED $failcount Fail $NORMAL has appeared while the installation please check logs file for more details "
	fi
	printf '\n '
	read -p "Press any key to exit the script."
}
nms_update(){
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Backing up old Nixxis File" "#####$NORMAL"
	#Copying files
	printf '%-*s %s\r ' $col "Copying files" "$NORMAL [ ... ] $NORMAL"
	cp -rf /etc/asterisk /etc/asterisk.bak >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Copying files" "$GREEN [ Done ] $NORMAL"
	
	printf '\n %-15s %-40s %s\n ' "$MAGENTA#####" "Update Nixxis File" "#####$NORMAL"	
	# downloading nixxis pack
	printf '%-*s %s\r ' $col "Downloading Nixxis pack" "$NORMAL [ ... ] $NORMAL"
	pushd /usr/src/asterisk/ >> /var/log/nixxis/installation.log 2>&1
	wget -O NixxisInstall.zip $NixxisUri --user install --password qR4Eqkuz >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Downloading Nixxis pack" "$GREEN [ Done ] $NORMAL"
# unpacking
	printf '%-*s %s\r ' $col "Unpacking Nixxis pack" "$NORMAL [ ... ] $NORMAL" 
	yum install -y unzip >> /var/log/nixxis/installation.log 2>&1
	unzip -o NixxisInstall.zip -d ./nixxis >> /var/log/nixxis/installation.log 2>&1
	printf '%-*s %s\n ' $col "Unpacking Nixxis pack" "$GREEN [ Done ] $NORMAL"
# Installing Nixxis Asterisk configuration files
	printf '%-*s %s\r ' $col "Placing Nixxis pack elements" "$NORMAL [ ... ] $NORMAL"
	pushd /usr/src/asterisk/nixxis/Asterisk/ >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/Asterisk/etc/* /etc >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/Asterisk/usr/* /usr >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/Asterisk/var/* /var >> /var/log/nixxis/installation.log 2>&1
	cp -rf /usr/src/asterisk/nixxis/Asterisk/srv/* /srv >> /var/log/nixxis/installation.log 2>&1
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
	
	# Check if os is supported RedHat.
	if rpm -qa \*-release | grep -Ei "RedHat" | cut -d"-" -f3 | grep -iho "8" > /dev/null 2>&1; then 
		echo "RedHat 8 Installed" >> /var/log/nixxis/installation.log
		osversion="8"
	elif rpm -qa \*-release | grep -Ei "RedHat" | cut -d"-" -f3 | grep -iho "7" > /dev/null 2>&1; then 
			echo "RedHat 7 Installed" >> /var/log/nixxis/installation.log
			osversion="7"
		else 
			printf '%-*s %s\n ' 10 "$RED [ ✗ Fail ] $NORMAL" "Nixxis only support RedHat 7 & 8"
			printf '\n\n %-25s %s\n ' " " "$RED Nixxis only support RedHat 7 & 8 $NORMAL" >> /var/log/nixxis/installation.log
			exit
	fi
			printf '%-*s %s\n ' 10 "$GREEN [ ✓ Ok ] $NORMAL" "OS RedHat $osversion installed"
	
	
	# ensure Time Is Correct
	if /etc/init.d/ntpd status > /dev/null 2>&1; then
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
pkgs=( "gcc gcc-c++" "libxml2-devel" "ncurses-devel" "dialog" "curl" "curl-devel" "whois.x86_64" "net-snmp" "kernel-devel" "bison" "openssl-devel" "sox" "wget" "mysql-devel" "sqlite-devel" "libtool-ltdl-devel" "samba-client" "perl-libwww-perl" "mlocate" "ntp" "rsync" "lighttpd" "php-cli" "nano" "vsftpd" "fail2ban")
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