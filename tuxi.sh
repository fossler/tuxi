#!/usr/bin/env bash

# general vars
LSB_BIN=$(which lsb_release)

hostn (){
  hostname -s
}

os_name (){
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

os_release (){
  if [[ -z $LSB_BIN ]]; then
    cat /etc/os-release | grep "VERSION_ID" | cut -d'"' -f2
  else
    lsb_release -rs
  fi
}

os_codename (){
  if [[ -z $LSB_BIN ]]; then
    cat /etc/os-release | grep -e "VERSION_CODENAME=" | cut -d= -f2
  else
    lsb_release -cs
  fi
}

os_kernel_release (){
  uname -r
}

net_ip_internal (){
  hostname -I
}

net_ip_external (){
  dig +short myip.opendns.com @resolver1.opendns.com &> /dev/zero
  if [[ $? -ne 0 ]]; then
    printf "Could not resolve\n"
  fi
}

net_domain (){
  if [[ $(hostname -d) == "" ]]; then
    printf "%-3s\n" "---"
  else
    hostname -d
  fi
}

net_inet_con_state (){
  ping -c 1 google.com &> /dev/zero && echo -e "$GOOD"Connected"$NORMAL_FONT" || echo -e "$BAD"Disconnected"$NORMAL_FONT"
}

# Color definitions
COLOR='\e[33m' # Yellow
BAD='\e[31m' # Red
GOOD='\e[32m' # Green
NORMAL_FONT='\e[0m'

printf "x============[ Systeminfo ]============================================[ $(date) ]===============\n"
printf ""
exit
