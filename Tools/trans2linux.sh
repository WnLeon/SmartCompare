#!/bin/bash
# Date: 2023-2-22
# Author: LeonWu
# Mail: Leon_wun@163.com
# Function: trans tools to linux
# Version: V1.1
# Update: 2023-2-23

cd /c/Users/38454/PycharmProjects/SmartCompare/Tools/RsyncClient
`pwd`/rsync.exe /cygdrive/C/Users/38454/PycharmProjects/SmartCompare --delete -aAH --numeric-ids --safe-links --partial --quiet -e '"C:/Users/38454/PycharmProjects/SmartCompare/Tools/RsyncClient/ssh.exe" -p 22 -o Compression=no -o StrictHostKeyChecking=no' root@43.254.55.108:/root