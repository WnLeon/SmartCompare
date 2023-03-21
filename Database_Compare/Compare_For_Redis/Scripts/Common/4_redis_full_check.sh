#!/bin/bash
# Date: 2023-3-13
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: redis full check
# Version: V1.1
# Update: 2023-3-13

# 引入公共函数和配置文件
CURRENT_DIR=$(dirname $(readlink -f "$0"))
#echo $CURRENT_DIR
task_config=$1
#task_config=DemoTask
source $(dirname $CURRENT_DIR)/Common/0_0_Common_Format.sh
myDos_unix "$(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}"
source $(dirname $(dirname $CURRENT_DIR))/Conf/${task_config}/${task_config}
workdir=$(dirname $(dirname $CURRENT_DIR))/Workspace/${task_config}
resultdir=$workdir/result

#work/resultdir check
if [ ! -d $workdir ];then
  mkdir -p $workdir
fi

if [ ! -d $resultdir ];then
  mkdir -p $resultdir
fi

function download-tools() {
  sudo find ./ -name redis-full-check > /dev/null
  if [ $? -ne 0 ];then
    wget https://github.com/alibaba/RedisFullCheck/releases/download/release-v1.4.8-20200212/redis-full-check-1.4.8.tar.gz -O $workdir/redis-full-check-1.4.8.tar.gz && tar -zxvf $workdir/redis-full-check-1.4.8.tar.gz -C $workdir
  else
    echo "Please recheck if tool is ready"
  fi

}

function tips() {
    echo "----------------------------------------"
    echo "  -s, --source=SOURCE               源redis库地址（ip:port），如果是集群版，那么需要以分号（;）分割不同的db，只需要配置主或者从的其中之一。例如：10.1.1.1:1000;10.2.2.2:2000;10.3.3.3:3000。"
    echo "-p, --sourcepassword=Password     源redis库密码"
    echo "--sourceauthtype=AUTH-TYPE    源库管理权限，开源reids下此参数无用。
          --sourcedbtype=               源库的类别，0：db(standalone单节点、主从)，1: cluster（集群版），2: 阿里云
          --sourcedbfilterlist=         源库需要抓取的逻辑db白名单，以分号（;）分割，例如：0;5;15表示db0,db5和db15都会被抓取"
    echo "-t, --target=TARGET               目的redis库地址（ip:port）"
    echo "-a, --targetpassword=Password     目的redis库密码
      --targetauthtype=AUTH-TYPE    目的库管理权限，开源reids下此参数无用。
      --targetdbtype=               参考sourcedbtype
      --targetdbfilterlist=         参考sourcedbfilterlist "
    echo "-d, --db=Sqlite3-DB-FILE          对于差异的key存储的sqlite3 db的位置，默认result.db
      --comparetimes=COUNT          比较轮数"
    echo "-m, --comparemode=                比较模式，1表示全量比较，2表示只对比value的长度，3只对比key是否存在，4全量比较的情况下，忽略大key的比较
      --id=                         用于打metric
      --jobid=                      用于打metric
      --taskid=                     用于打metric"
     echo "-q, --qps=                        qps限速阈值
      --interval=Second             每轮之间的时间间隔
      --batchcount=COUNT            批量聚合的数量
      --parallel=COUNT              比较的并发协程数，默认5
      --log=FILE                    log文件
      --result=FILE                 不一致结果记录到result文件中，格式：'db    diff-type    key    field'
      --metric=FILE                 metric文件
      --bigkeythreshold=COUNT       大key拆分的阈值，用于comparemode=4 "
    echo "-f, --filterlist=FILTER           需要比较的key列表，以分号（;）分割。例如：'abc*|efg|m*'表示对比'abc', 'abc1', 'efg', 'm', 'mxyz'，不对比'efgh', 'p'。
  -v, --version"
    echo "----------------------------------------"
}
cd $workdir/redis-full-check-1.4.8 && ./redis-full-check