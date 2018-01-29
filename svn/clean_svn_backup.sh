#!/bin/bash

# svn backups file dir.
SVN_BAKDIR=/backups/svn_backups
PROJECT1_NAME=dingding
PROJECT2_NAME=zen

# Reserved 7 files.
COUNT=7

ls -t ${SVN_BAKDIR}/${PROJECT1_NAME}* | tail -n +$[$COUNT+1] | xargs rm -f
ls -t ${SVN_BAKDIR}/${PROJECT2_NAME}* | tail -n +$[$COUNT+1] | xargs rm -f
