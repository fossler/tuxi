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

sys_check_reboot (){
  if [[ -f /var/run/reboot-required ]]; then
    printf "$BAD%-30s$NORMAL_FONT" '*** System reboot required ***'
  else
    printf "$GOOD%-30s$NORMAL_FONT" '*** No reboot required ***'
  fi
}  

sys_desk_env (){
  printf "$XDG_CURRENT_DESKTOP"
}

sys_check_updates (){
  UPDATES=$(usr/lib/update-notifier/apt-check 2>&1)
  if [[ $UPDATES == '0;0' ]]; then
    printf "no updates are available"
  else
    UPDATES=$(usr/lib/update-notifier/apt-check --human-readable | sed -n '1p')
    SEC_UPDATES=$(usr/lib/update-notifier/apt-check --human-readable | sed -n '2p')
    printf "$UPDATES\n"
    printf "%-72s %-40s" '' '$SEC_UPDATES'
  fi
}  

user_login_shell (){
  USER_LOGIN_SHELL=${SHELL##*/}
  printf "$USER_LOGIN_SHELL"
}

user_login_shell_ver (){
  case "$USER_LOGIN_SHELL" in
    bash)
      BASH_VER=$(bash --version | grep "bash.*version" | cut -d' ' -f4 | cut -d'(' -f1)
      echo "$BASH_VER"
      ;;
    csh)
      # TBD
      ;;
    dash)
      # TBD
      ;;
    ksh)
      # TBD
      ;;
    tcsh)
      # TBD
      ;;
    zsh)
      ZSH_VER=$(zsh --version | cut -d' ' -f2)
      ;;
  esac
  
}
user_group_membership (){
  USER_GROUPS=$(id | cut -d'=' -f4)
  OIFS=$IFS
  IFS=,
  COUNTER=0
  declare -r SPLITTER=7
  for i in $USER_GROUPS; do
      if [[ $COUNTER -eq $SPLITTER ]]; then
         printf "\n|\n"
         printf "%-20s" '|'
         printf "$i  "
         counter=0
	    else
	       printf "$i  "
      fi
      (( counter++ ))
  done
  printf "\n"
  IFS=$OIFS
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

net_nic_state (){
  ip -o link show $1 2> /dev/zero | awk '{print $9}'
}

net_get_active_nic (){
  ip route show | grep "default" | cut -d" " -f3
}

net_get_gateway (){
  VAR_GATEWAY=$(ip route show | grep -E 'default.*'$1'' | cut -d" " -f3)
  if [[ -z $VAR_GATEWAY ]]; then
    printf "%-3s" "---"
  else
    printf "%-15s" "$VAR_GATEWAY"
  fi
}

net_mac_addr (){
  VAR_MAC=$(ip -o link show $1 2> /dev/zero | awk '{print $17}')
  if [[ -z $VAR_MAC ]]; then
    printf "%-3s" "---"
  else
    printf "%-15s" "$VAR_MAC"
  fi
}

net_nic_ip (){
  NIC_VAR=$(ifconfig $1 2> /dev/zero | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}')
  if [[ -z $NIC_VAR ]]; then
    printf "%-3s\n" "---"
  else
    printf "$NIC_VAR"
  fi
}

net_nic_netmask (){
  NM_VAR=$(ifconfig $1 2> /dev/zero | grep "Mask" | cut -d":" -f4)
  if [[ z- $NM_VAR ]]; then
    printf "%-3s\n" "---"
  else
    printf "$NM_VAR"
  fi
}  

net_dhcp_srv (){
  grep "DHCPACK" /var/log/syslog | tail 1 | cut -d' ' -f10
}

net_dns_srv (){
  if [[ -z $DISPLAY ]]; then
    ACTIVE_NIC=$(ip route show | grep "default" | head -1 | cut -d" " -f5)
    MY_NS=$(nmcli device show $ACTIVE_NIC | grep "IP4.DNS" | cut -d":" -f2
    printf "$MY_NS"
  else
    cat /etc/resolv.conf | grep "nameserver" | sed 's/nameserver//'
  fi
}

hw_cpu (){
  cat /proc/cpuinfo | grep "model name" | head -1 | cut -d":" -f2 | sed 's/[[:space:]]//'
}

# Color definitions
COLOR='\e[33m' # Yellow
BAD='\e[31m' # Red
GOOD='\e[32m' # Green
NORMAL_FONT='\e[0m'

printf "x============[ Systeminfo ]============================================[ $(date) ]===============\n"
printf ""
exit
