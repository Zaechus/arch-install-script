#!/bin/sh -e

confirm_password () {
    local pass1="a"
    local pass2="b"
    until [[ $pass1 == $pass2 && $pass2 ]]; do
        printf "$1: " >&2 && read -rs pass1
        printf "\n" >&2
        printf "confirm $1: " >&2 && read -rs pass2
        printf "\n" >&2
    done
    echo $pass2
}

# Pre
sudo loadkeys us
sudo timedatectl set-ntp true

# Check boot mode
[[ ! -d /sys/firmware/efi ]] && printf "Not booted in UEFI mode. Aborting..." && exit 1

# Choose disk
while :
do
    sudo fdisk -l
    printf "\nDisk to install to (e.g. /dev/sda): " && read my_disk
    [[ -b $my_disk ]] && break
done

part1="$my_disk"1
part2="$my_disk"2
part3="$my_disk"3
if [[ $my_disk == *"nvme"* ]]; then
    part1="$my_disk"p1
    part2="$my_disk"p2
    part3="$my_disk"p3
fi

root_part=$part2

my_root=$part2

# Timezone
until [[ -f /usr/share/zoneinfo/$region_city ]]; do
    printf "Region/City (e.g. 'America/Denver'): " && read region_city
    [[ ! $region_city ]] && region_city="America/Denver"
done

# Host
while :
do
    printf "Hostname: " && read my_hostname
    [[ $my_hostname ]] && break
done

# Users
root_password=$(confirm_password "root password")

installvars () {
    echo my_disk=$my_disk part1=$part1 part2=$part2 part3=$part3 \
        root_part=$root_part my_root=$my_root \
        region_city=$region_city my_hostname=$my_hostname \
        root_password=$root_password
}

printf "\nDone with configuration. Installing...\n\n"

# Install
sudo $(installvars) sh src/installer.sh

# Chroot
sudo cp src/iamchroot.sh /mnt/root/ && \
    sudo $(installvars) arch-chroot /mnt /bin/bash -c 'sh /root/iamchroot.sh; rm /root/iamchroot.sh; exit' && \
    printf '\n`sudo artix-chroot /mnt /bin/bash` back into the system to make any final changes.\n\nYou may now poweroff.\n'
