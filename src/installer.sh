#!/bin/sh -e

printf "label: gpt\n,550M,U\n,,L\n" | sfdisk $my_disk

# Format and mount partitions
mkfs.fat -F 32 $part1

mkfs.btrfs $my_root

# Create subvolumes
mount $my_root /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
umount -R /mnt

# Mount subvolumes
mount -t btrfs -o compress=zstd,subvol=root $my_root /mnt
mkdir /mnt/home
mount -t btrfs -o compress=zstd,subvol=home $my_root /mnt/home

mkdir /mnt/boot
mount $part1 /mnt/boot

[[ $(grep 'vendor' /proc/cpuinfo) == *"Intel"* ]] && ucode="intel-ucode"
[[ $(grep 'vendor' /proc/cpuinfo) == *"Amd"* ]] && ucode="amd-ucode"

# Install base system and kernel
pacstrap /mnt base base-devel btrfs-progs efibootmgr grub $ucode dhcpcd wpa_supplicant networkmanager 
pacstrap /mnt linux linux-firmware linux-headers mkinitcpio
genfstab -U /mnt > /mnt/etc/fstab
