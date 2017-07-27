#! /bin/bash
#-------------------------------------------------------------------------------
# Name:         systemInfo.sh
# Purpose:      monitor system info
# Author:       Zhao Jiankai
# Created:      23/09/2016
# Copyright:    Copyright © 2016 Wisedu. All Rights Reserved.
# Licence:      Free to use!
# Version:      alpha!!! (0.1)
#-------------------------------------------------------------------------------

# Check OS Type
os=$(uname -o)
echo -e "Operating System Type :" $tecreset $os

# Check OS Release Version and Name
cat /etc/redhat-release > /tmp/osrelease
echo -n -e "OS Name :" `cat /tmp/osrelease | awk '{print $1, "\t", $2}'`
echo
echo -n -e "OS Version :" `cat /tmp/osrelease | awk '{print $(NF-1)}'`
echo

# Check Architecture
architecture=$(uname -m)
echo -e "Architecture :" $architecture

# Check Kernel Release
kernelrelease=$(uname -r)
echo -e "Kernel Release :" $kernelrelease

# Check hostname
echo -e "Hostname :" $HOSTNAME

# Check IP
osVersion=`cat /tmp/osrelease | awk '{print $(NF-1)}' | awk -F. '{print $1}'`
if [ $osVersion -lt 6 ]; then
    ip=$(hostname -i)
else
    ip=$(hostname -I)
fi
echo -e "IP :" $ip

# Check DNS
nameservers=$(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}')
echo -e "Name Servers :" $nameservers 

# Check Logged In Users
who>/tmp/who
echo -e "Logged In users :" 
cat /tmp/who

# Check RAM and SWAP Usages
#free -h | grep -v + > /tmp/ramcache
free -m | grep -v + > /tmp/ramcache
echo -e "Ram Usages :"
cat /tmp/ramcache | grep -v "Swap"
echo -e "Swap Usages :"
cat /tmp/ramcache | grep -v "Mem"

# Check Disk Usages
df -h| grep 'Filesystem\|^/dev/*' > /tmp/diskusage
echo -e "Disk Usages :"
cat /tmp/diskusage

# Check Load Average
loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $12 $13 $14}')
echo -e "Load Average :" $loadaverage

# Check System Uptime
tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e "System Uptime Days/(HH:MM) :" $tecuptime

# Remove Temporary Files
rm /tmp/osrelease /tmp/who /tmp/ramcache /tmp/diskusage

