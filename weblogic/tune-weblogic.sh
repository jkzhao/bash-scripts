#!/bin/bash
# author:wdfang
# date:2015-11-17
# version:1.0

# check if user is root
if [ $(id -u) != "0" ]; then
    echo -e "\e[1;31;1m[Error]: You must be root to run this script, please use root to run it!\e[0m"
    exit 1
fi


# Sysctl
cat >> /etc/sysctl.conf <<EOF

# Start: Weblogic Tuning : `date`
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
fs.file-max = 65536
net.ipv4.ip_local_port_range = 1024 65000
net.core.rmem_default = 262144
net.core.rmem_max = 2097152
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
# Stop: Weblogic Tuning : `date`
EOF
sysctl -p

# LIMIT
cat >> /etc/security/limits.conf <<EOF
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
EOF

cat >> /etc/pam.d/login <<EOF
session    required     pam_limits.so
EOF

cat >> /etc/profile <<EOF
if [ \$USER = "oracle" ] ; then 
if [ \$SHELL = "/bin/ksh" ]; then
        ulimit -p 16384
        ulimit -n 65536
else
        ulimit -u 16384 -n 65536
    fi
fi
EOF
