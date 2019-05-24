#!/usr/bin/expect 
set ip [lindex $argv 0]
set port [lindex $argv 1]
set username [lindex $argv 2]
set password [lindex $argv 3]
set timeout -1
spawn ssh -p $port $username@$ip
expect {
    "password" {send "$password\r";}
    "yes/no" {send "yes\r";exp_continue}
}
interact
