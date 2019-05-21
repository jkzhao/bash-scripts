#!/bin/bash

. ./environment_check_module.sh
DOWNLOAD_DOMAIN="http://authdev.wisedu.com"


config_centos6_yum_repo(){
    # 如果是CentOS 6，需要配置yum源
    if [ ! -f "/etc/yum.repos.d/epel.repo" ]; then 
        echo "开始配置yum源..."
        #[ -f "/etc/yum.repos.d/CentOS-Base.repo" ] && mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
        if ls /etc/yum.repos.d/*.repo &>/dev/null; then
            for name in `ls /etc/yum.repos.d/*.repo &>/dev/null`;do mv $name ${name}.bak;done #备份原有的repo文件
        fi
        if which wget &>/dev/null; then
            wget -SO /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo &>/dev/null
        else
            \cp -f CentOS-Base.repo /etc/yum.repos.d/
        fi
        sed -i 's#/$releasever#/6#g;s#/$basearch#/x86_64#g' /etc/yum.repos.d/CentOS-Base.repo
        if [ $? -eq 0 ]; then 
            yum -y install epel-release &>/dev/null
            echo "yum源配置完成"
        else
            echo "yum源配置失败，程序退出"
            exit 12
        fi
    fi
}

install_os_util(){
    get_os_version
    #if [[ `echo "${os_version} >= 6" | bc` -eq 1 ]] && [[ `echo "${os_version} < 7" | bc` -eq 1 ]]; then
    ret=`echo ${os_version} | awk '{if($1>=6 && $1<7) {printf 0} else {printf 1}}'`
    if [ ${ret} -eq 0 ]; then
        config_centos6_yum_repo
    fi 
    yum install -y $1 &>/dev/null
}

########################
# 安装Nginx            #
########################
openresty_uninstall(){
    rpm -e --nodeps $1 &>/dev/null
    [ -L "/usr/local/nginx" ] && rm -f /usr/local/nginx #删除符号链接
    [ -d "/usr/local/openresty" ] && rm -rf /usr/local/openresty
    #if [[ `echo "${os_version} >= 6" | bc` -eq 1 ]] && [[ `echo "${os_version} < 7" | bc` -eq 1 ]]; then
    ret=`echo ${os_version} | awk '{if($1>=6 && $1<7) {printf 0} else {printf 1}}'`
    if [ ${ret} -eq 0 ]; then
        [ -f "/etc/init.d/nginx" ] && rm -f /etc/init.d/nginx
    else
        [ -f "/etc/systemd/system/nginx.service" ] && rm -f /etc/systemd/system/nginx.service
        systemctl daemon-reload
    fi
}
openresty_install(){
    # $1 传入OpenResty版本
    if [ $# -ne 1 ]; then
        echo -e "\033[31mNginx安装失败，请传入OpenResty版本\033[0m"
        return
    fi

    get_os_version 
    if rpm -ql openresty_for_centos6-$1-1.x86_64 &>/dev/null; then #安装时采用的是自己制作的rpm包，这样可以省去编译安装nginx所需要的大量时间。同时为了保证Nginx安装的幂等性，可能安装过了又安装一遍，在卸载时需要先执行一条命令，否则再次安装rpm包时会报错说冲突。
        openresty_uninstall openresty_for_centos6-$1-1.x86_64
    elif rpm -ql openresty_for_centos7-$1-1.x86_64 &>/dev/null; then
        openresty_uninstall openresty_for_centos7-$1-1.x86_64
    fi

    # 如果是CentOS 6，需要配置yum源
    #if [[ `echo "${os_version} >= 6" | bc` -eq 1 ]] && [[ `echo "${os_version} < 7" | bc` -eq 1 ]]; then #如果系统是CentOS 6，需要配置yum源
    ret=`echo ${os_version} | awk '{if($1>=6 && $1<7) {printf 0} else {printf 1}}'`
    [ ${ret} -eq 0 ] && config_centos6_yum_repo #如果系统是CentOS 6，需要配置yum源

    #安装OpenResty依赖包
    echo "安装Nginx依赖包，请稍后..."
    yum install readline-devel pcre-devel openssl-devel gcc -y &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Nginx依赖包安装完成"
    else
        echo "Nginx依赖包安装失败，请检查yum源，并检查服务器是否能连接上网，然后请重新执行脚本。"
        exit 7
    fi

    #安装OpenResty
    echo "开始安装Nginx..."
    curl ${DOWNLOAD_DOMAIN} &>/dev/null
    [ $? -ne 0 ] && echo "无法连接下载服务器，请咨询公司相关人员——赵建凯" && exit 11
    which wget &>/dev/null
    [ $? -ne 0 ] && yum install -y wget &>/dev/null
    #if [[ `echo "${os_version} >= 6" | bc` -eq 1 ]] && [[ `echo "${os_version} < 7" | bc` -eq 1 ]]; then
    ret=`echo ${os_version} | awk '{if($1>=6 && $1<7) {printf 0} else {printf 1}}'`
    if [ ${ret} -eq 0 ]; then
        #CentOS 6安装OpenResty
        wget -N -P /usr/local/ ${DOWNLOAD_DOMAIN}/nginx/openresty_for_centos6-$1-1.x86_64.rpm &>/dev/null
        rpm -ivh /usr/local/openresty_for_centos6-$1-1.x86_64.rpm
    else
        # CentOS 7安装OpenResty
        wget -N -P /usr/local/ ${DOWNLOAD_DOMAIN}/nginx/openresty_for_centos7-$1-1.x86_64.rpm &>/dev/null
        rpm -ivh /usr/local/openresty_for_centos7-$1-1.x86_64.rpm
    fi
    [ ! -L "/usr/local/nginx" ] && ln -sv /usr/local/openresty /usr/local/nginx &>/dev/null
    echo "Nginx安装完成，nginx家目录为/usr/local/nginx"
}
openresty_start(){
    get_os_version
    ngx_ret=1 #结果为1表示启动成功，为0表示失败
    # CentOS 6和CentOS 7启动方式不同
    #if [[ `echo "${os_version} >= 6" | bc` -eq 1 ]] && [[ `echo "${os_version} < 7" | bc` -eq 1 ]]; then
    ret=`echo ${os_version} | awk '{if($1>=6 && $1<7) {printf 0} else {printf 1}}'`
    if [ ${ret} -eq 0 ]; then
        error_result_nginx=`service nginx start` 
        [ $? -ne 0 ] && ngx_ret=0
    else
        error_result_nginx=`systemctl start nginx.service`
        [ $? -ne 0 ] && ngx_ret=0
    fi
}
openresty_reload(){
    get_os_version
    ngx_ret=1 #结果为1表示启动成功，为0表示失败
    #if [[ `echo "${os_version} >= 6" | bc` -eq 1 ]] && [[ `echo "${os_version} < 7" | bc` -eq 1 ]]; then
    ret=`echo ${os_version} | awk '{if($1>=6 && $1<7) {printf 0} else {printf 1}}'`
    if [ ${ret} -eq 0 ]; then
        error_result_nginx=`service nginx reload`
        [ $? -ne 0 ] && ngx_ret=0
    else
        error_result_nginx=`systemctl reload nginx.service`
        [ $? -ne 0 ] && ngx_ret=0
    fi
}


########################
# 安装Redis            #
########################


########################
# 安装JDK              #
########################
jdk_envionment_variables(){
    export JAVA_HOME=/usr/java/$1
    export PATH=$JAVA_HOME/bin:$PATH
    export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
    sed -i '$a\export JAVA_HOME=/usr/java/'"$1"'' /etc/profile
    sed -i '$a\export PATH=$JAVA_HOME/bin:$PATH' /etc/profile
    sed -i '$a\export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar' /etc/profile
    source /etc/profile
}
jdk_install(){
    echo "开始安装JDK..."
    get_jdk_version
    # $1 传入JDK版本，比如 7
    if [[ $# -ne 1 ]]; then
        echo -e "\033[31mJDK安装失败，传入JDK版本\033[0m"
        return 
    fi

    if [[ $1 -eq ${jdk_num} ]]; then
        echo "JDK $1 已安装"
        return
    fi

    curl www.baidu.com &>/dev/null 
    [ $? -ne 0 ] && echo "服务器无法联网，无法下载安装包，程序退出！" && exit 13
    curl ${DOWNLOAD_DOMAIN} &>/dev/null
    [ $? -ne 0 ] && echo "无法连接下载服务器，请咨询公司相关人员——赵建凯" && exit 11
    if ! which wget &>/dev/null; then 
        install_os_util wget
    fi

    if [[ $1 -eq 7 ]]; then
        [ ! -d "/usr/java" ] && mkdir /usr/java
        echo "正在下载jdk，请耐心等待(具体下载时间视网络情况，下载完成后会有提示，切勿Ctrl+C)..."
        wget -N -P /usr/local ${DOWNLOAD_DOMAIN}/jdk/jdk-7u80-linux-x64.tar.gz &>/dev/null
        echo "解压JDK包，请耐心等待..."
        tar zxf /usr/local/jdk-7u80-linux-x64.tar.gz -C /usr/java/
        grep "jdk1.7.0_80" /etc/profile &>/dev/null 
        [ $? -ne 0 ] && jdk_envionment_variables jdk1.7.0_80
        echo "JDK安装完成，打开新的终端即可验证新的JDK版本！"
    elif [[ $1 -eq 8 ]]; then
        [ ! -d "/usr/java" ] && mkdir /usr/java
        echo "正在下载jdk，请稍后..."
        wget -N -P /usr/local ${DOWNLOAD_DOMAIN}/jdk/jdk-8u181-linux-x64.tar.gz &>/dev/null
        echo "解压JDK包，请耐心等待..."
        tar zxf /usr/local/jdk-8u181-linux-x64.tar.gz -C /usr/java/ 
        grep "jdk1.8.0_181" /etc/profile &>/dev/null 
        [ $? -ne 0 ] && jdk_envionment_variables jdk1.8.0_181
        echo "JDK安装完成，打开新的终端即可验证新的JDK版本！"
    else
        echo -e "\033[31mNo such jdk version provided to install. Please check the parameter.\033[0m"
    fi
}


########################
# 安装Tomcat           #
########################
tomcat_install(){
    curl www.baidu.com &>/dev/null
    [ $? -ne 0 ] && echo "服务器无法联网，无法下载安装包，程序退出！" && exit 13
    curl ${DOWNLOAD_DOMAIN} &>/dev/null
    [ $? -ne 0 ] && echo "无法连接下载服务器，请咨询公司相关人员——赵建凯" && exit 11
    if ! which wget &>/dev/null; then
        install_os_util wget
    fi

    if [ $1 -eq 7 ]; then
        #echo "正在下载tomcat，请稍后..."
        wget -N -P /usr/local ${DOWNLOAD_DOMAIN}/tomcat/apache-tomcat-7.0.92.tar.gz &>/dev/null
        #echo "解压安装tomcat..."
        tar zxf /usr/local/apache-tomcat-7.0.92.tar.gz -C /usr/local/
        tomcat_origin_home="/usr/local/apache-tomcat-7.0.92"
    elif [ $1 -eq 8 ]; then
        #echo "正在下载tomcat，请稍后..."
        wget -N -P /usr/local ${DOWNLOAD_DOMAIN}/tomcat/apache-tomcat-8.5.38.tar.gz &>/dev/null
        #echo "解压安装tomcat..."
        tar zxf /usr/local/apache-tomcat-8.5.38.tar.gz -C /usr/local/
        tomcat_origin_home="/usr/local/apache-tomcat-8.5.38"
    else
        echo "没有这个版本的jdk提供安装！"
        exit 8
    fi 
    
    echo ${tomcat_origin_home}
}

tomcat_restart(){
    #$1 tomcat家目录
    tomcat_stop $1
    echo "正在启动tomcat..."
    $1/bin/startup.sh &>/dev/null
}

tomcat_stop(){
    #$1 tomcat家目录
    if ps -ef|grep "$1" |grep -v "grep" &>/dev/null; then
        echo "正在停止tomcat..."
        $1/bin/shutdown.sh &>/dev/null
        sleep 8
    fi
    if ps -ef|grep "$1" |grep -v "grep" &>/dev/null; then
      tomcat_pid=`ps -ef | grep $1 | grep -v "grep" | awk '{print $2}'`
      kill -9 ${tomcat_pid} &>/dev/null
    fi 
}

config_tomcat_datasource(){
    # $1 传入tomcat家目录，这个方法执行完后，还需要修改jndi名称
    sed -i '/\/Context/i\    <Resource name="jdbc/emap"' $1/conf/context.xml
    sed -i '/\/Context/i\          auth="Container"' $1/conf/context.xml
    sed -i '/\/Context/i\          type="javax.sql.DataSource"' $1/conf/context.xml
    sed -i '/\/Context/i\          username="gemini"' $1/conf/context.xml
    sed -i '/\/Context/i\          password="123456"' $1/conf/context.xml
    sed -i '/\/Context/i\          driverClassName="oracle.jdbc.driver.OracleDriver"' $1/conf/context.xml
    sed -i '/\/Context/i\          url="jdbc:oracle:thin:@172.16.4.77:1521:urpdb"' $1/conf/context.xml
    sed -i '/\/Context/i\          maxWait="9000"' $1/conf/context.xml
    sed -i '/\/Context/i\          maxIdle="30"' $1/conf/context.xml
    sed -i '/\/Context/i\          maxActive="50"/>' $1/conf/context.xml
}



########################
# 安装Weblogic         #
########################




########################
# 安装emap             #
########################
emap_install_for_tomcat(){
    #$1 传入tomcat家目录
    useradd weblogic
    echo 'wiseduapp' | passwd --stdin weblogic &>/dev/null
}

#emap_install_for_weblogic(){
    #
#}





########################
# main test            #
########################
environment_install(){
    openresty_install 1.11.2.5
    jdk_install 7
}

#environment_install
