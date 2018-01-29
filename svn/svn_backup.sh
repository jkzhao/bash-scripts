#!/bin/bash
# 全量备份

SVN_DIR=/var/www/svndata
PROJECT1_NAME=zen
PROJECT2_NAME=dingding
SVN_BAKDIR=/backups/svn_backups
VERSION=`svnlook youngest ${SVN_DIR}/${PROJECT_NAME}`
LOG=/tmp/fullsvn.log

svnadmin dump /var/www/svndata/zen > ${SVN_BAKDIR}/${PROJECT1_NAME}_full_$(date +%Y%m%d) &>/dev/null
svnadmin dump /var/www/svndata/zen > ${SVN_BAKDIR}/${PROJECT2_NAME}_full_$(date +%Y%m%d) &>/dev/null

if [ $? -eq 0 ];then
    echo $VERSION > /tmp/version
else
    echo "#####################################fullsvn bak is failed" >> $LOG
fi
