#!/usr/bin/env bash

# general vars
# ##############################################################
LSB_BIN=$(which lsb_release)
GLXINFO_BIN=$(which glxinfo)

# Color definitions
YELLOW='\e[33m' # Yellow
RED='\e[31m' # Red
GREEN='\e[32m' # Green
DEFAULTF='\e[0m'

# Systeminfo
# ##############################################################

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

# User info
# ##############################################################

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

# System Security
# ##############################################################

sec_check_ufw_state (){
  systemctl status ufw.service | grep -w "Active: inactive" &> /dev/zero
  if [[ $? -eq 0 ]]; then
    echo -e "$BAD"disabled"$NORNAL_FONT"
  else
    echo -e "$GOOD"enabled"$NORNAL_FONT"
  fi
}

sec_check_aa_service (){
  systemctl status apparmor.service | grep -w "Active: inactive" &> /dev/zero
  if [[ $? -eq 0 ]]; then
    echo -e "$BAD"inactive "(dead)""$NORNAL_FONT"
  else
    echo -e "$GOOD"active "(exited)""$NORNAL_FONT"
  fi
}

sec_check_arp_protection (){
  PKG_STATE=$(dpkg-query --show --showformat='${Status}\n' arpon 2> /dev/null | grep "install ok installed")
  if [[ $? -eq 0 ]]; then
    echo "ARPON installed"
  else
    echo "not installed"
  fi
}

# Network info
# ##############################################################

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

mask2cdr (){
    # Assumes there's no "255." after a non-255 byte in the mask
    if [[ $1 == --- ]]; then
      echo "---"
    else
      local x=${1##*255.}
      set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
      x=${1%%$3*}
      echo $(( $2 + (${#x}/4) ))
    fi
 }

 net_nic_summary () {
  INDEX=0
  NICs=($(ip -o link show | awk '{print $2}' | grep -v lo | sed 's/.$//' | paste -s))

  for i in "${NICs[@]}"
  do
    NIC_details[$INDEX]+=''$i' '$(NIC_state $i)' '$(NIC_ip $i)' '$(get_gateway $i)' '$(NIC_netmask $i)' '$(mask2cdr $(NIC_netmask $i))' '$(MAC_addr $i)''
    (( INDEX++ ))
  done
  printf "| %-17s| %-8s| %-15s| %-15s| %-15s| %-5s| %-5s" 'NIC' 'State' 'IP' 'Gateway' 'Netmask' 'CIDR' 'MAC'
  printf "\n"
  printf "| ---------------------------------------------------------------------------------------------------------\n"
  for i in "${!NIC_details[@]}"
  do
    printf "| %-17s| %-8s| %-15s| %-15s| %-15s| %-5s| %-15s" ${NIC_details[i]}
    printf "\n"
  done
}

# Hardware & Ressources
# ##############################################################

hw_cpu (){
  cat /proc/cpuinfo | grep "model name" | head -1 | cut -d":" -f2 | sed 's/[[:space:]]//'
}

hw_cpu_cores (){
  cat /proc/cpuinfo | grep processor | wc -l
}

hw_cpu_HT (){
  grep flags /proc/cpuinfo | grep -wo ht &> /dev/zero
  if [[ $? -eq 0 ]]; then
    printf "Yes\n"
  else
    printf "No\n"
  fi
}

hw_system_vendor (){
  SYS_VENDOR=/sys/devices/virtual/dmi/id/sys_vendor
  if [[ -f $SYS_VENDOR ]]; then
    cat $SYS_VENDOR
  else
    printf "not available\n"
  fi
}

hw_system_model (){
  PODUCT_NAME=/sys/devices/virtual/dmi/id/product_name
  if [[ -f $PODUCT_NAME ]]; then
    cat $PODUCT_NAME
  else
    printf "not available\n"
  fi
}

hw_system_version (){
  SYS_VER=/sys/devices/virtual/dmi/id/product_version
  if [[ -f $SYS_VER ]]; then
    cat $SYS_VER
  else
    printf "not available\n"
  fi
}

hw_gpu_card (){
  if [[ -z $lshw ]];then
    printf " not available\n"
  else
    lshw -C display 2> /dev/zero | grep product | cut -d":" -f2 | sed 's/[[:space:]]//'
    # lspci -vnn | grep VGA -A 12
  fi
}

hw_gpu_renderer (){
  glxinfo &> /dev/zero
  if [[ $? -ne 0 ]]; then
    printf " not available\n"
  elif [[ -z $GLXINFO_BIN ]]; then
    printf " not available\n"
  else
    glxinfo 2> /dev/zero | grep "OpenGL renderer string" | cut -d':' -f2 | sed 's/[[:space:]]//'
  fi
}

hw_gpu_memory_size (){
  glxinfo &> /dev/zero
  if [[ $? -ne 0 ]]; then
    printf " not available\n"
  elif [[ -z $GLXINFO_BIN ]]; then
    printf " not available\n"
  else
    glxinfo 2> /dev/zero | grep "Video memory:" | cut -d: -f2
  fi
}

hw_gpu_opengl_version (){
  glxinfo &> /dev/zero
  if [[ $? -ne 0 ]]; then
    printf " not available\n"
  elif [[ -z $GLXINFO_BIN ]]; then
    printf " not available\n"
  else
    glxinfo 2> /dev/zero | grep "OpenGL version string:" | cut -d: -f2
  fi
}

hw_mobo_vendor (){
  MOBO_VENDOR=/sys/devices/virtual/dmi/id/board_vendor
  if [[ -f $MOBO_VENDOR ]]; then
    cat $MOBO_VENDOR
  else
    printf "not available\n"
  fi
}

hw_mobo_version (){
  MOBO_VERSION=/sys/devices/virtual/dmi/id/board_version
  if [[ -f $MOBO_VERSION ]]; then
    cat $MOBO_VERSION
  else
    printf "not available\n"
  fi
}

hw_mobo_name (){
  MOBO_NAME=/sys/devices/virtual/dmi/id/board_name
  if [[ -f $MOBO_NAME ]]; then
    cat $MOBO_NAME
  else
    printf "not available\n"
  fi
}

hw_mobo_bios_vendor (){
  BIOS_VENDOR=/sys/devices/virtual/dmi/id/bios_vendor
  if [[ -f $BIOS_VENDOR ]]; then
    cat $BIOS_VENDOR
  else
    printf "not available\n"
  fi
}

hw_mobo_bios_version (){
  BIOS_VERSION=/sys/devices/virtual/dmi/id/bios_version
  if [[ -f $BIOS_VERSION ]]; then
    cat $BIOS_VERSION
  else
    printf "not available\n"
  fi
}

hw_mobo_bios_date (){
  BIOS_DATE=/sys/devices/virtual/dmi/id/bios_date
  if [[ -f $BIOS_DATE ]]; then
    cat $BIOS_DATE
  else
    printf "not available\n"
  fi
}

# TUI
# ##############################################################


printf "x============[ Systeminfo ]============================================[ $(date) ]===============\n"
printf ""
exit
