#!/bin/sh
###Description:This script is used to install centos6 epel yum.
###Written by: jkzhao - jkzhao@wisedu.com  
###History: 2015-11-25 First release.

# Check the latest epel-release rpm is installed or not.
rpmname=epel-release

checkEpel() {
  if rpm -qa | grep $1 &>/dev/null; then
    echo "The epel-release rpm is installed already."
    exit 0
  fi
}
checkEpel $rpmname

epelInstall() {
  # Download the latest epel-release rpm from http://dl.fedoraproject.org/pub/epel/6/x86_64.
  if [ `uname -m` == 'x86_64' ]; then
    wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm &>/dev/null
  else
    wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm  &>/dev/null
  fi

  # Check the latest epel-release rpm is changed or not. If download successfully,install the latest epel-release rpm. 
  if [ $? -eq 0 ]; then
    rpm -Uvh epel-release*rpm &>/dev/null
  else
    echo "Please check the latest epel-release rpm from http://dl.fedoraproject.org/pub/epel/6/x86_64."
    exit 5
  fi

  # Change the yumrepo configuration.
  sed -i s/https/http/g /etc/yum.repos.d/epel.repo
}
epelInstall
