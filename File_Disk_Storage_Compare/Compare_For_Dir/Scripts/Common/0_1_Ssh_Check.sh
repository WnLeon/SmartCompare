#!/bin/bash
# Date: 2023-3-2
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Conf vm ssh auto login
# Version: V1.1
# Update: 2023-3-3

# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
source $(dirname $(dirname $CURRENT_DIR))/Conf/$task_config/$task_config

if [ "$login_way" = "password" ];then
    # 操作机支持redhat/centos/ubuntu
    sshpass -V >/dev/null
    if [ $? -ne 0 ];then
      apt-get -y install sshpass || yum  -y install sshpass
    fi
    if [ $? -ne 0 ];then
      myLog 4 "sshpass not ready and install failed!!!" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
    fi

    # pass or secret key login choose
    sshpass -p${src_password} ssh -p${src_port} -o StrictHostKeyChecking=no "$src_username"@"$src_ip" 'pwd' >/dev/null
    if [ $? -eq 0 ];then
      myLog 2 "src login success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
    else
      myLog 4 "src login failed, please check network or login_information" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
    fi

    sshpass -p${dest_password} ssh -p${dest_port}  -o StrictHostKeyChecking=no "$dest_username"@"$dest_ip" 'pwd' >/dev/null
    if [ $? -eq 0 ];then
      myLog 2 "dest login success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
    else
      myLog 4 "dest login failed, please check network or login_information" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
    fi

else

   ssh -i $(dirname $(dirname $CURRENT_DIR))/Conf/$src_id_rsa -p${src_ip} -o StrictHostKeyChecking=no "$src_username"@"$src_ip" 'pwd'>/dev/null
   if [ $? -eq 0 ];then
      myLog 2 "src login success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
   else
      myLog 4 "src login failed, please check network or login_information" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
   fi
   ssh -i $(dirname $(dirname $CURRENT_DIR))/Conf/$dest_id_rsa -p${dest_ip} -o StrictHostKeyChecking=no "$dest_username"@"$dest_ip" 'pwd'>/dev/null
   if [ $? -eq 0 ];then
     myLog 2 "dest login success" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/info.log
   else
     myLog 4 "dest login failed, please check network or login_information" | tee -a $(dirname $(dirname $CURRENT_DIR))/Logs/error.log && exit
   fi
fi

# auto conf sshkey
<<!
sshpass -p${src_password} ssh -p${src_ip} "$src_username"@"$src_ip" -o StrictHostChecking=no "
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_`hostname`_rsa
  cat ~/.ssh/id_`hostname`_rsa.pub  >> ~/.ssh/authorized_keys
  ssh-copy-id `whoami`@$local_ip"

sshpass -p${dest_password} ssh -p${dest_ip} "$dest_username"@"$dest_ip" -o StrictHostChecking=no "
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_`hostname`_rsa
  cat ~/.ssh/id_`hostname`_rsa.pub  >> ~/.ssh/authorized_keys
  ssh-copy-id `whoami`@$local_ip"
!