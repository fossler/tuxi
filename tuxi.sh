#!/usr/bin/env bash

hostn (){
  hostname -s
}

os_name (){
  LSB_BIN=$(which lsb_release)
  if [[ -z $LSB_BIN ]]; then
    cat /etc/os-release | grep -e "^ID" | cut -d= -f2
  else
    lsb_release -is
  fi
}

os_type (){
  uname -o
}

os_arch (){
  uname -m
}

printf "x============[ Systeminfo ]============================================[ $(date)]===============\n"
printf ""
exit
