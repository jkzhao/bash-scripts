#!/bin/bash
file="computerInfo"
#显示机器信息 过滤第一行和空行
awk '{if (NR > 1 && $1 != ""){printf "%-2s %-25s %-15s %-5s %-5s\n", NR-1")",$6,$1,$3,$4}}' $file 
read -p "please choose which machine to login:" number
#将信息存入变量
read ip port user password <<< $(echo `awk 'NR-1=="'$number'"{print $1,$2,$4,$5}' $file`)
./core.ex $ip $port $user $password
