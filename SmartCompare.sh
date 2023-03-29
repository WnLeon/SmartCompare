#!/bin/bash
# Date: 2023-3-3
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: Start Program
# Version: V1.1
# Update: 2023-3-4

# ENV
CURRENT_DIR=$(dirname $(readlink -f "$0"))
echo ${CURRENT_DIR}
Dir1=${CURRENT_DIR}/Database_Compare
Dir2=${CURRENT_DIR}/File_Disk_Storage_Compare
Dir3=${CURRENT_DIR}/File_Object_Storage_Compare

Dir1_mysql=$Dir1/Compare_For_Mysql/Bin
Dir2_dir=$Dir2/Compare_For_Dir/Bin

# FUNC
function tips(){

  echo -e "\033[34m -------------------------------------------------- \033[0m" #blue
  echo -e "\033[36m ------------------ SmartCompare ------------------ \033[0m" #sky blue
  echo -e "\033[34m -------------------------------------------------- \033[0m"
  echo -e "\033[32m - [1] DatabaseCompare \033[0m"                                  #green
  echo -e "\033[34m - [2] FileStorageCompare \033[0m"
  echo -e "\033[36m - [3] ObjectStorageCompare \033[0m"
  echo -e "\033[34m -------------------------------------------------- \033[0m"
}

function start(){
  read -t 10 -p "Choose what kind of module you need ([1]/[2]/[3]) : " module
  echo ''
  echo -e "\033[36m ------------------ $(date '+%Y-%m-%d %H:%M:%S') ------------------ \033[0m"
  if [ -z $module ];then
    echo -e "\033[32m -Time Out Default Module Set File_Disk_storage_Compare- \033[0m"
    module=2
  fi
  case "${module}" in
  1)
    echo -e "\033[36m ------------------ i am Database_Compare ------------------ \033[0m"
    cd ./Database_Compare
  ;;
  2)
    echo -e "\033[36m ------------------ i am File_Disk_storage_Compare ------------------ \033[0m"
    cd $Dir2_dir && bash CompareStart.sh $1
  ;;
  3)
    echo -e "\033[36m ------------------ i am File_Object_Storage_Compare ------------------ \033[0m"
  ;;
  *)
    echo -e "\033[36m ------------------ i am ... ------------------ \033[0m"
  ;;
  esac
}


# EXEC
tips
start $1