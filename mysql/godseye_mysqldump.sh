#!/bin/bash
###Description:This script is used to dump database godseye_db.
###Written by: jkzhao - jkzhao@wisedu.com  
###History: 2016-06-16 First release
###Notification: 

# 基础配置变量(也可通过读取参数获得)
DUMPED_SCRIPT_FILE_NAME=godseye-db-init-script.sql
DUMP_HOME_DIR=/root
DATABASE=godseye_db_refactor
DB_USER=root
DB_PWD=wisedu123

# 全量记录dump的表
FULL_RECORDS_TABLE_ARR=(
'agent_sink_type'
'basic_dataitem'
'log_category'
'log_category_field'
'log_category_filter'
'log_category_template'
'log_default_field'
'log_field_analyzer'
'message_communicate_type'
'message_exchange'
'basic_module'
'scheduler_job_category'
'scheduler_job_type'
'security_menu'
'security_user_role'
)

# 只dump表结构,不dump记录的表
NO_RECORDS_TABLE_ARR=(
'agent_instance'
'agent_source'
'api_search_apply'
'api_search_apply_history'
'api_search_apply_status'
'basic_app'
'basic_group'
'basic_host'
'basic_template'
'basic_school'
'basic_user'
'basic_user_app'
'log_field_warning'
'log_type'
'log_type_field'
'log_type_filter'
'log_type_template'
'message_source'
'message_sink'
'message_stream'
'monitor_standardlog4j_alert'
'monitor_standardlog4j_param'
'resource_elasticsearch_statistics'
'scheduler_job'
'scheduler_job_metadata'
'scheduler_job_trigger'
'scheduler_job_sqoop'
'search_indices'
'search_mapping_field'
'search_mapping_type'
'security_privilege'
'security_role'
'security_user_role'
'security_user_login'
'stream_topology'
'stream_spout'
'stream_spout_metadata'
'stream_bolt'
'stream_bolt_metadata'
)

# 导出前刷写所有表并施加锁
mysql -u$DB_USER -p$DB_PWD -e 'FLUSH TABLES WITH READ LOCK' &>/dev/null
mysql -u$DB_USER -p$DB_PWD -e 'FLUSH LOGS' &>/dev/null

# 步骤1: dump 全量记录相关的表,遍历数组:FULL_RECORDS_TABLE_ARR
# 类似:
#mysqldump -h<hostname> -u<username> -p <databasename>  <table1>
#<table2> <table3>
#--single-transaction > dumpfile.sql
for((i=0;i<${#FULL_RECORDS_TABLE_ARR[@]};i++))
do
    mysqldump -u$DB_USER -p$DB_PWD $DATABASE ${FULL_RECORDS_TABLE_ARR[i]} >>${DUMP_HOME_DIR}/${DUMPED_SCRIPT_FILE_NAME} 2>/dev/null
done

# 步骤2: dump 表结构不带记录相关的表,遍历数组:NO_RECORDS_TABLE_ARR(追加入上面的文件中),并指定where条件,过滤所有记录
# 类似:
#mysqldump -h<hostname> -u<username> -p <databasename>
#<table4> --where 'CONDITION',
#<table5> --where 'CONDITION'
#--single-transaction >> dumpfile.sql 
for((i=0;i<${#NO_RECORDS_TABLE_ARR[@]};i++))
do
    mysqldump -u$DB_USER -p$DB_PWD $DATABASE ${NO_RECORDS_TABLE_ARR[i]} -d >>${DUMP_HOME_DIR}/${DUMPED_SCRIPT_FILE_NAME} 2>/dev/null
done

# 导出完了释放锁
mysql -u$DB_USER -p$DB_PWD -e 'UNLOCK TABLES' &>/dev/null

# 加入创建数据库的语句
sed -i "1 i\CREATE DATABASE $DATABASE DEFAULT CHARACTER SET utf8;" ${DUMP_HOME_DIR}/${DUMPED_SCRIPT_FILE_NAME}
sed -i "2 i\USE $DATABASE;" ${DUMP_HOME_DIR}/${DUMPED_SCRIPT_FILE_NAME} 

