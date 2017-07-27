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
echo -e "\033[35mOperating System Type :\033[0m" $tecreset $os

# Check OS Release Version and Name
cat /etc/os-release | grep 'NAME\|VERSION' | grep -v 'VERSION_ID' | grep -v 'PRETTY_NAME' > /tmp/osrelease
echo -e "\033[35mOS Name :\033[0m" `cat /tmp/osrelease | grep -w "NAME" | awk -F'"' '{print $2}'`
echo -e "\033[35mOS Version :\033[0m" `cat /tmp/osrelease | grep -v "NAME" | cut -f2 -d\"`

# Check Architecture
architecture=$(uname -m)
echo -e "\033[35mArchitecture :\033[0m" $architecture

# Check Kernel Release
kernelrelease=$(uname -r)
echo -e "\033[35mKernel Release :\033[0m" $kernelrelease

# Check hostname
echo -e "\033[35mHostname :\033[0m" $HOSTNAME

# Check IP
ip=$(hostname -I)
echo -e "\033[35mIP :\033[0m" $ip

# Check DNS
nameservers=$(cat /etc/resolv.conf | sed '1 d' | awk '{print $2}')
echo -e "\033[35mName Servers :\033[0m" $nameservers 

# Check Logged In Users
who>/tmp/who
echo -e "\033[35mLogged In users :\033[0m" 
cat /tmp/who

# Check RAM and SWAP Usages
free -h | grep -v + > /tmp/ramcache
echo -e "\033[35mRam Usages :\033[0m"
cat /tmp/ramcache | grep -v "Swap"
echo -e "\033[35mSwap Usages :\033[0m"
cat /tmp/ramcache | grep -v "Mem"

# Check Disk Usages
df -h| grep 'Filesystem\|^/dev/*' > /tmp/diskusage
echo -e "\033[35mDisk Usages :\033[0m"
cat /tmp/diskusage

# Check Load Average
loadaverage=$(top -n 1 -b | grep "load average:" | awk '{print $12 $13 $14}')
echo -e "\033[35mLoad Average :\033[0m" $loadaverage

# Check System Uptime
tecuptime=$(uptime | awk '{print $3,$4}' | cut -f1 -d,)
echo -e "\033[35mSystem Uptime Days/(HH:MM) :\033[0m" $tecuptime

# Remove Temporary Files
rm /tmp/osrelease /tmp/who /tmp/ramcache /tmp/diskusage

# Look for the program which occupys network flow most

