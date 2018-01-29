#!/bin/sh
###Description:This script is used to start Nodemanager
###Written by: jkzhao - jkzhao@wisedu.com on 2015-10-23

NODEMANAGER_HOME=/opt/Oracle/Middleware/wlserver_10.3/server/bin

###check the user is weblogic or not
if [ `whoami` != 'weblogic' ]; then
    echo "You must be weblogic user to execute this program."
    exit 2
fi

cd $NODEMANAGER_HOME
nohup ./startNodeManager.sh >> /home/weblogic/logs/NodeManager.out 2>&1 &
