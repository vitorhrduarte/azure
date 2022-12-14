##!/usr/bin/env bash
set -e

## Variables

LAN_SUFFIX="lan"
VM_GATEWAY="192.168.88.1"
VM_DNS_SERVER="192.168.88.1"

## Functions
showHelp() {
cat << EOF

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
WARNING: Must adjust the cloud-init file.
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

ENV VARS (in ~/.bashrc for instance):
VM_SUDO_USER_PASS - This one need to encoded so that Cloud-Init can handle it
VM_SUDO_USER_SSH_PUB_KEYS - Pub Key for the sudo user


Usage:

bash go.sh --help/-h  [for help]
bash go.sh -v/--vmname <input hostname> -i/--ip <host ip> -u/--username <host sudo username>

Example: bash go.sh -v ccp01.lan -i 192.168.0.20/24 -u ubuntu

-h, -help,          --help                 Display help

-v, -vmname,        --vmname               Host Name

-i, -ip,            --ip                   Host IP

-u, -username       --username             Host Sudo username

EOF
}


options=$(getopt -l "help::,ip:,vmname:,username:" -o "h::i:v:u:" -a -- "$@")

eval set -- "$options"

while true
do
case $1 in
-h|--help)
    showHelp
    exit 0
    ;;
-v|--vmname)
    shift
    VM_NAME=$1
    ;;
-i|--ip)
    shift
    VM_IP=$1
    ;;
-u|--username)
    shift
    VM_SUDO_USER=$1
    ;;
--)
    shift
    break
    exit 0
    ;;
esac
shift
done



###################
##
## CORE
##
###################

## Remove Existing user-data file
rm -rf user-data

## Create new user-data File
cat <<EOF > user-data
#cloud-config
autoinstall:
  apt:
    disable_components: []
    geoip: true
    preserve_sources_list: false
    primary:
    - arches:
      - amd64
      - i386
      uri: http://pt.archive.ubuntu.com/ubuntu
    - arches:
      - default
      uri: http://ports.ubuntu.com/ubuntu-ports
  drivers:
    install: false
  identity:
    hostname: $PXE_SERVER
    password: $VM_SUDO_USER_PASS
    realname: $VM_SUDO_USER
    username: $VM_SUDO_USER
  kernel:
    package: linux-generic
  keyboard:
    layout: us
    toggle: null
    variant: ''
  locale: en_US.UTF-8
  network:
    ethernets:
      eth0:
        addresses:
        - $VM_IP
        gateway4: $VM_GATEWAY
        nameservers:
          addresses:
          - $VM_DNS_SERVER
          search:
          - $LAN_SUFFIX
    version: 2
  ssh:
    allow-pw: false
    authorized-keys:
    - $VM_SUDO_USER_SSH_PUB_KEYS
    install-server: true
  storage:
    grub:
      reorder_uefi: False
    swap:
      size: 0
    config:
    - ptable: gpt
      path: /dev/sda
      wipe: superblock
      preserve: false
      name: ''
      grub_device: false
      type: disk
      id: disk-sda
    - device: disk-sda
      size: 1127219200
      wipe: superblock
      flag: boot
      number: 1
      preserve: false
      grub_device: true
      type: partition
      id: partition-0
    - fstype: fat32
      volume: partition-0
      preserve: false
      type: format
      id: format-0
    - device: disk-sda
      size: 2147483648
      wipe: superblock
      flag: ''
      number: 2
      preserve: false
      grub_device: false
      type: partition
      id: partition-1
    - fstype: ext4
      volume: partition-1
      preserve: false
      type: format
      id: format-1
    - device: disk-sda
      size: 71885127680
      wipe: superblock
      flag: ''
      number: 3
      preserve: false
      grub_device: false
      type: partition
      id: partition-2
    - name: ubuntu-vg
      devices:
      - partition-2
      preserve: false
      type: lvm_volgroup
      id: lvm_volgroup-0
    - name: ubuntu-lv
      volgroup: lvm_volgroup-0
      size: 35940990976B
      wipe: superblock
      preserve: false
      type: lvm_partition
      id: lvm_partition-0
    - fstype: ext4
      volume: lvm_partition-0
      preserve: false
      type: format
      id: format-2
    - path: /
      device: format-2
      type: mount
      id: mount-2
    - path: /boot
      device: format-1
      type: mount
      id: mount-1
    - path: /boot/efi
      device: format-0
      type: mount
      id: mount-0
  updates: security
  late-commands:
  - 'echo "$VM_SUDO_USER ALL=(ALL) NOPASSWD:ALL" > /target/etc/sudoers.d/$VM_SUDO_USER-nopw'
  - chmod 440 /target/etc/sudoers.d/$VM_SUDO_USER-nopw
  version: 1
EOF
