#!/usr/bin/env bash
clear
#  tuxi - A shellscript that collects system infos
#  SOURCE: https://github.com/fossler/tuxi
#
#  Author: Mirzet Kadic | https://github.com/fossler | https://plus.google.com/+MirzetKadic
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.


# general vars
# ##############################################################
RUID=$(env | grep "SUDO_USER" | cut -d"=" -f1)
LSB_BIN=$(which lsb_release)
GLXINFO_BIN=$(which glxinfo)
LSHW_BIN=$(which lshw)

# COLOR definitions
YELLOW='\e[33m'
RED='\e[31m'
GREEN='\e[32m'
DEFAULTF='\e[0m'

# Systeminfo
# ##############################################################

hostn (){
  hostname -s
}

os_name (){
  if [[ -z ${LSB_BIN} ]]; then
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
  if [[ -z ${LSB_BIN} ]]; then
    cat /etc/os-release | grep "VERSION_ID" | cut -d'"' -f2
  else
    lsb_release -rs
  fi
}

os_codename (){
  if [[ -z ${LSB_BIN} ]]; then
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
    printf "${RED}%-30s${DEFAULTF}" '*** System reboot required ***'
  else
    printf "${GREEN}%-30s${DEFAULTF}" '*** No reboot required ***'
  fi
}

sys_desk_env (){
  printf "${XDG_CURRENT_DESKTOP}"
}

sys_check_updates (){
  UPDATES=$(/usr/lib/update-notifier/apt-check 2>&1)
  if [[ -f /usr/lib/update-notifier/apt-check ]]; then
    if [[ ${UPDATES} == '0;0' ]]; then
      printf "no updates are available"
    else
      UPDATES=$(/usr/lib/update-notifier/apt-check --human-readable | sed -n '1p')
      SEC_UPDATES=$(/usr/lib/update-notifier/apt-check --human-readable | sed -n '2p')
      printf "${UPDATES}\n"
      printf "|%-72s %-40s" '' "${SEC_UPDATES}"
    fi
  else
    echo "Not supported on this distro"
  fi
}

# User info
# ##############################################################

user_login_shell (){
  USER_LOGIN_SHELL=${SHELL##*/}
  printf "%-s\n" "${USER_LOGIN_SHELL}"
}

user_login_shell_ver (){
	user_login_shell &> /dev/null
  case "${USER_LOGIN_SHELL}" in
    bash)
      BASH_VER=$(bash --version | grep "bash.*version" | cut -d' ' -f4 | cut -d'(' -f1)
      echo "${BASH_VER}"
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
  OIFS=${IFS}
  IFS=,
  COUNTER=0
  declare -r SPLITTER=6
  for i in ${USER_GROUPS}; do
      if [[ ${COUNTER} -eq ${SPLITTER} ]]; then
         printf "\n|\n"
         printf "%-20s" '|'
         printf "${i}  "
         COUNTER=0
	    else
	       printf "%-s  " "${i}"
      fi
      (( COUNTER++ ))
  done
  printf "\n"
  IFS=${OIFS}
}

# System Security
# ##############################################################

sec_check_ufw_state (){
systemctl --type service --all | grep -w "ufw.service" 1> /dev/null
if [[ $? -ne 0 ]]; then
  echo "Service not found"
else
  systemctl status ufw.service | grep -w "Active: inactive" &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "${RED}"disabled"${DEFAULTF}"
  else
    echo -e "${GREEN}"enabled"${DEFAULTF}"
  fi
fi
}

sec_check_aa_service (){
systemctl --type service --all | grep -w "apparmor.service" 1> /dev/null
if [[ $? -ne 0 ]]; then
  echo "Service not found"
else
  systemctl status apparmor.service | grep -w "Active: inactive" &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "${RED}"inactive "(dead)""${DEFAULTF}"
  else
    echo -e "${GREEN}"active "(exited)""${DEFAULTF}"
  fi
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


net_ip_internal (){
  hostname -I
}

net_ip_external (){
  # dig +short myip.opendns.com @resolver1.opendns.com 2> /dev/null
	dig TXT +short o-o.myaddr.l.google.com @ns1.google.com 2> /dev/null | awk -F'"' '{ print $2}'
  if [[ "${PIPESTATUS[0]}" -ne 0 ]]; then
    printf "${RED}%-s${DEFAULTF}" "Could not resolve"
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
  ping -c 1 google.com &> /dev/null && echo -e "${GREEN}"Connected"${DEFAULTF}" || echo -e "${RED}"Disconnected"${DEFAULTF}"
}

net_nic_state (){
  ip -o link show ${1} 2> /dev/null | awk '{print $9}'
}

net_get_active_nic (){
  ip route show | grep "default" | cut -d" " -f3
}

net_get_gateway (){
  VAR_GATEWAY=$(ip route show | grep -E 'default.*'${1}'' | cut -d" " -f3)
  if [[ -z ${VAR_GATEWAY} ]]; then
    printf "%-3s" "---"
  else
    printf "%-15s" "${VAR_GATEWAY}"
  fi
}

net_mac_addr (){
  VAR_MAC=$(ip -o link show ${1} 2> /dev/null | awk '{print $17}')
  if [[ -z ${VAR_MAC} ]]; then
    printf "%-3s" "---"
  else
    printf "%-15s" "${VAR_MAC}"
  fi
}

net_nic_ip (){
	NIC_VAR=$(ip -o -f inet addr show ${1} 2> /dev/null | grep -Po 'inet \K[\d.]+')
  if [[ -z ${NIC_VAR} ]]; then
    printf "%-3s\n" "---"
  else
    printf "${NIC_VAR}"
  fi
}

net_nic_netmask (){
  NM_VAR=$(ifconfig ${1} 2> /dev/null | grep "Mask" | cut -d":" -f4)
  if [[ -z ${NM_VAR} ]]; then
    printf "%-3s\n" "---"
  else
    printf "%-s" "${NM_VAR}"
  fi
}

net_dhcp_srv (){
  grep "DHCPACK" /var/log/syslog | tail -1 | sed -n -e 's/^.*from //p'
}

net_dns_srv (){
  if [[ ${XDG_SESSION_TYPE} == x11 ]] || [[ ${XDG_SESSION_TYPE} == mir ]]; then
    ACTIVE_NIC=$(ip route show | grep "default via" | head -1 | cut -d" " -f5)
    MY_NS=($(nmcli device show ${ACTIVE_NIC} | grep "IP4.DNS" | cut -d":" -f2))
    for i in "${MY_NS[@]}"; do
      printf "%-s " "${i}"
    done
  else
    MY_NS=($(cat /etc/resolv.conf | grep "nameserver" | sed 's/nameserver//'))
    for i in "${MY_NS[@]}"; do
      printf "%-s " "${i}"
    done
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
    NIC_details[$INDEX]+=''$i' '$(net_nic_state $i)' '$(net_nic_ip $i)' '$(net_get_gateway $i)' '$(net_nic_netmask $i)' '$(mask2cdr $(net_nic_netmask $i))' '$(net_mac_addr $i)''
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
  grep flags /proc/cpuinfo | grep -wo ht &> /dev/null
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
  PRODUCT_NAME="/sys/devices/virtual/dmi/id/product_name"
  if [[ -f $PRODUCT_NAME ]]; then
    cat $PRODUCT_NAME
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
if [[ -z $LSHW_BIN ]];then
 printf " not available\n"
else
	OIFS=$IFS
	IFS=$'\n'
	GPUs=( $(lshw -C display 2> /dev/null | grep product | cut -d":" -f2 | sed 's/[[:space:]]//'))
	COUNTER=0
	declare -r SPLITTER=1
	for i in "${GPUs[@]}"; do
		if [[ $COUNTER -eq $SPLITTER ]]; then
			 #printf "\n|"
			 printf "\n%-10s" '|'
			 printf "$i  "
			 COUNTER=0
		else
			 printf "$i  "
		fi
		(( COUNTER++ ))
	done
fi
IFS=$OIFS
}

hw_gpu_renderer (){
  glxinfo &> /dev/null
  if [[ $? -ne 0 ]]; then
    printf " not available\n"
  elif [[ -z $GLXINFO_BIN ]]; then
    printf " not available\n"
  else
    glxinfo 2> /dev/null | grep "OpenGL renderer string" | cut -d':' -f2 | sed 's/[[:space:]]//'
  fi
}

hw_gpu_memory_size (){
  glxinfo &> /dev/null
  if [[ $? -ne 0 ]]; then
    printf " not available\n"
  elif [[ -z $GLXINFO_BIN ]]; then
    printf " not available\n"
  else
    glxinfo 2> /dev/null | grep "Video memory:" | cut -d: -f2
  fi
}

hw_gpu_opengl_version (){
  glxinfo &> /dev/null
  if [[ $? -ne 0 ]]; then
    printf " not available\n"
  elif [[ -z $GLXINFO_BIN ]]; then
    printf " not available\n"
  else
    glxinfo 2> /dev/null | grep "OpenGL version string:" | cut -d: -f2
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

hw_ram_usage (){
	free -h | grep -v "Swap" | xargs -L1 echo "|" | sed 's/Mem: //' | column -t
}

hw_storage_usage (){
  #df -hT 2> /dev/null | sed '2,${/^\//!d}' | grep -v "\(loop[0-9]\|.snapshot\|tmpfs\)" | xargs -L1 echo "|" | column -s" " -t
  #df -hTP 2> /dev/null | sed '2,${/^\//!d}' | grep -v loop[0-9] | grep -v .snapshot | xargs -L1 echo "|" | column -s" " -t
  echo ""
  #df -Th -t ext2 -t ext4 -t cifs -t nfs -t zfs
}

# TUI
# ##############################################################

printf "x========[ Systeminfo ]==========================================[ $(date) ]================================\n"
printf "|\n"
printf "| $YELLOW%-9s$DEFAULTF %-19s $YELLOW%-8s$DEFAULTF %-16s\n" "Hostname:" "$(hostn)" "Domain:" "$(net_domain)"
printf "|\n"
printf "| $YELLOW%-8s$DEFAULTF %-20s $YELLOW%-5s$DEFAULTF %-26s $YELLOW%-5s$DEFAULTF %-16s\n" "OS-Name:" "$(os_name)" "Type:" "$(os_type)" "Arch:" "$(os_arch)"
printf "| $YELLOW%-8s$DEFAULTF %-20s $YELLOW%-8s$DEFAULTF %-22s $YELLOW%-5s$DEFAULTF %-16s\n" "Release:" "$(os_release)" "Codename:" "$(os_codename)" "Kernel:" "$(os_kernel_release)"
printf "| $YELLOW%-8s$DEFAULTF %-20s\n" "Desktop Environment:" "$(sys_desk_env)"
printf "|%-63s $YELLOW%-8s$DEFAULTF %-40s\n" '' 'Updates:' "$(sys_check_updates)"
printf "| $YELLOW%-9s$DEFAULTF %-20s $YELLOW%-8s\n$DEFAULTF" "Uptime:" "$(uptime -p)" "$(sys_check_reboot)"
printf "|\n"
printf "x========[ User info ]============================================================================================================\n"
printf "|\n"
printf "| $YELLOW%-9s$DEFAULTF %-10s $YELLOW%-5s$DEFAULTF %-12s $YELLOW%-4s$DEFAULTF %-6s $YELLOW%-4s$DEFAULTF %-6s $YELLOW%-12s$DEFAULTF %-4s %-6s\n" "Username:" "$USER" "Home:" "$HOME" "UID:" "$(id -u $USER)" "GID:" "$(id -g $USER)" "Login Shell:" "$(user_login_shell)" "$(user_login_shell_ver)"
printf "|\n"
printf "| $YELLOW%-17s$DEFAULTF %-20s\n" "Group Membership:" "$(user_group_membership)"
printf "|\n"
printf "x========[ System security ]======================================================================================================\n"
printf "|\n"
printf "| $YELLOW%-11s$DEFAULTF %-20s $YELLOW%-16s$DEFAULTF %-26s $YELLOW%-15s$DEFAULTF %-16s \n" "ufw-Status:" "$(sec_check_ufw_state)" "AppArmor-Status:" "$(sec_check_aa_service)" "ARP-Protection:" "$(sec_check_arp_protection)"
printf "|\n"
printf "x========[ Network info ]=========================================================================================================\n"
printf "|\n"
printf "| $YELLOW%-7s$DEFAULTF %-15s $YELLOW%-9s$DEFAULTF %-20s $YELLOW%-12s$DEFAULTF %-15s $YELLOW%-12s$DEFAULTF %-40s\n" "WAN-IP:" "$(net_ip_external)" "WAN-State:" "$(net_inet_con_state)" "DHCP Server:" "$(net_dhcp_srv)" "DNS Servers:" "$(net_dns_srv)"
printf "|\n"
printf "$(net_nic_summary)\n"
printf "|\n"
printf "x========[ Hardware & Ressources ]================================================================================================\n"
printf "|\n"
printf "| $YELLOW%-14s$DEFAULTF %-27s $YELLOW%-6s$DEFAULTF %-29s $YELLOW%-5s$DEFAULTF %-16s\n" "System-Vendor:" "$(hw_system_vendor)" "Model:" "$(hw_system_model)" "Version:" "$(hw_system_version)"
printf "| $YELLOW%-13s$DEFAULTF %-28s $YELLOW%-6s$DEFAULTF %-29s $YELLOW%-5s$DEFAULTF %-16s\n" "Board-Vendor:" "$(hw_mobo_vendor)" "Model:" "$(hw_mobo_name)" "Version:" "$(hw_mobo_version)"
printf "| $YELLOW%-12s$DEFAULTF %-29s $YELLOW%-8s$DEFAULTF %-27s $YELLOW%-5s$DEFAULTF %-16s\n" "BIOS-Vendor:" "$(hw_mobo_bios_vendor)" "Version:" "$(hw_mobo_bios_version)" "Date:" "$(hw_mobo_bios_date)"
printf "|\n"
printf "| $YELLOW%-7s$DEFAULTF %-71s $YELLOW%-6s$DEFAULTF %-10s $YELLOW%-3s$DEFAULTF %-4s\n" "CPU(s):" "$(hw_cpu)" "Cores:" "$(hw_cpu_cores)" "HT:" "$(hw_cpu_HT)"
printf "| $YELLOW%-7s$DEFAULTF %-71s $YELLOW%-6s$DEFAULTF %-22s\n" "GPU(s):" "$(hw_gpu_card)" "Memory:" "$(hw_gpu_memory_size)"
printf "| $YELLOW%-13s$DEFAULTF %-65s $YELLOW%-12s$DEFAULTF %-22s\n" "GLX-Renderer:" "$(hw_gpu_renderer)" "GLX-Version:" "$(hw_gpu_opengl_version)"
printf "|\n"
printf "| $YELLOW%-7s\n$DEFAULTF" "[ RAM ]"
printf "$(hw_ram_usage)\n"
printf "|\n"
printf "| $YELLOW%-11s\n$DEFAULTF" "[ Storage ]"
printf "$(df)\n"
#printf "$(df -hTP 2> /dev/null | sed '2,${/^\//!d}' | grep -v loop[0-9] | grep -v .snapshot | xargs -L1 echo "|" | column -s" " -t)"
printf "|\n"
printf "x========[ https://github.com/fossler/tuxi ]===========================================================================================\n"
exit
