#!/bin/bash

#常量
retval=1 #用于判断每个检查项是否通过，若最终仍为1，环境检查通过，为0则环境检查不通过
error_prompt1="\033[31m版本不对,请安装centos 6以上版本! \033[0m"
error_prompt2="\033[31m版本不对，请安装JDK 7! \033[0m"
error_prompt3="\033[31mJDK未安装，请安装JDK 7! \033[0m"
error_prompt4="\033[31m服务器无法联网，后续安装软件需要联网，请检查网络! \033[0m"
check_ok="\033[31m \xE2\x9C\x94 \033[0m" #https://www.utf8-chartable.de/unicode-utf8-table.pl?start=9984&number=128&names=-&utf8=string-literal
check_false="\033[31m \xE2\x9C\x98 \033[0m"
function echo_prompt(){
    # $1打印的文字描述，$2代表检查项目的结果，$3代表是否符合要求，$4代表提示原因
    echo -e "\033[35m$1\033[0m" $2 $3 $4 
}

########################
# 获取IP地址           #
########################
function get_ip(){
    ip_list=`hostname -I`
    echo $ip_list
}

########################
# 检测操作系统版本     #
########################
function get_os_version(){
    # $1 传入你需要检测的版本，比如 6
    # 这里考虑redhat、centos、ubuntu，其他一律识别为unknown
    if [ -f "/etc/redhat-release" ]; then
        os=`cat /etc/redhat-release`
        if [ -f /etc/os-release ]; then
            # freedesktop.org and systemd
            . /etc/os-release
            os_version=$VERSION_ID
        elif [ -f "/etc/lsb-release" ]; then
            if type lsb_release >/dev/null 2>&1; then
                os_version=$(lsb_release -sr)
            fi
        else
            os_version=$(cat /etc/redhat-release | awk '{print $7}')
        fi
    elif [ -f "/etc/lsb-release" ]; then #ubuntu
        os=`cat /etc/lsb-release | grep "DISTRIB_DESCRIPTION" | awk -F'"' '{print $2}'`
        if type lsb_release >/dev/null 2>&1; then
            # linuxbase.org
            os_version=$(lsb_release -sr)
        fi
    else 
        os="Unknow OS"
    fi

}

function check_os(){
    get_os_version
    # $1 传入你需要检测的版本，比如 6
    #if [[ `echo "${os_version} >= $1" | bc` -eq 1 ]]; then #有时候获取到的操作系统版本是6.5之类的浮点数，与整数进行比较时得借助于bc或awk,有些操作系统最小化安装时没有装bc，所以使用awk
    standard_os_version=$1
    ret=`echo ${os_version} ${standard_os_version} | awk '{if($1>=$2) {printf 0} else {printf 1}}'`
    if [ ${ret} -eq 0 ]; then
        #echo -e "\033[35m操作系统类型: \033[0m" ${os}  "\033[31m \xE2\x9C\x94 \033[0m"
        echo_prompt "操作系统类型:" "${os}" "${check_ok}" #变量最好加上双引号，否则如果一个变量的值是多个字符串中间有空格的，shell方法参数，但凡遇到空格就作为一个变量
    else
        #echo -e "\033[35m操作系统类型: \033[0m" ${os}  "\033[31m \xE2\x9C\x98 版本不对\033[0m"
        echo_prompt "操作系统类型:" "${os}" "${check_false}" "${error_prompt1}"
        retval=0
    fi
}

########################
# 检测CPU              #
########################
function check_cpu(){
    cpu_num=`cat /proc/cpuinfo | awk '/^processor/{print $3}' | wc -l`
    echo_prompt "CPU个数: " "${cpu_num}" "${check_ok}"
}

########################
# 检测内存             #
########################
function check_mem(){
    memory=`free -m | grep "Mem" | awk '{print $2}'`
    memory_rounding=`awk 'BEGIN{printf "%.0f\n",('${memory}'/1000)}' `GB #内存大小四舍五入
    echo_prompt "总内存大小: " "${memory_rounding}" "${check_ok}"
}

########################
# 检测磁盘             #
########################
function check_disk(){
    echo_prompt "磁盘使用情况: " "${check_ok}"
    df -h| grep 'Filesystem\|^/dev/*'
}

########################
# 检测网络             #
########################
function check_network(){
    curl www.baidu.com &>/dev/null
    if [ $? -eq 0 ]; then
        echo_prompt "网络: " "${check_ok}"
    else
        retval=0
        echo_prompt "网络: " "${check_false}" "${error_prompt4}"
    fi
}

########################
# 检测JDK              #
########################
function get_jdk_version(){
    jdk_info=`java -version 2>&1`
    if [ $? -eq 0 ]; then
        jdk_ver=`echo ${jdk_info} | grep "version" | awk -F'"' '{print $2}'`
        jdk_num=`echo ${jdk_ver} | awk -F'.' '{print $2}'`
    fi
}
function check_jdk(){
    get_jdk_version
    # $1 传入jdk版本，比如 7
    if [ -z "${jdk_num}" -o "${jdk_num}" == " " ]; then
        jdk_ver="No jdk was intalled."
        echo_prompt "JDK版本: " "${jdk_ver}" "${check_false}" "${error_prompt3}"
        retval=0
    elif [[ ${jdk_num} -ne $1 ]]; then
        echo_prompt "JDK版本: " "${jdk_ver}" "${check_false}" "${error_prompt2}"
        retval=0
    else
        echo_prompt "JDK版本: " "${jdk_ver}" "${check_ok}"
    fi
}

########################
# 检测Tomcat           #
########################
########## Todo ################
function get_tomcat_version(){
    # $1 传入tomcat家目录
    [ -d $1 ] && tomcat_version=`$1/bin/catalina.sh version |grep "Server version" |awk -F'/' '{print $2}'`
}

#function check_tomcat(){
#
#}




########################
# main test            #
########################
function check_environment(){
    check_os 6
    check_cpu
    check_mem
    check_disk
    check_network
    #check_jdk 7
    if [ ${retval} -eq 0 ]; then
        echo -e "\033[31m环境检查失败，请检查环境！\033[0m"
        exit 5
    else
        echo -e "\033[31m环境检查通过！下面将开始安装软件！\033[0m"
        echo ""
    fi
}

#check_environment
