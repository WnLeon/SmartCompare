#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Alarm tasks through WECOM BoT
# Version: V1.1
# Update: 2023-2-23

# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
#task_config=$1
task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
source $(dirname $(dirname $CURRENT_DIR))/Conf/$task_config

wecombot_url=$wecombot_url
alarm_time=`date '+%Y%m%d-%H%M%S'`
new_alarm_context="${alarm_time}-${alarm_context}"
#echo $wecombot_url
#echo $new_alarm_context

curl $wecombot_url -H 'Content-Type: application/json' -d '
   {
        "msgtype": "text",
        "text": {
            "content": "'${new_alarm_context}'"
        }
   }'
