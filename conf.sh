#!/bin/bash

# Simple configuration script that executes common commands for a plain & basic setup.
# NOTE: this is a personal script for my specific use case, requires manual tinkering.

# Variables
$hostnm=comfy
$usernm=joe
$locale=en_US.UTF-8
$timezn=/usr/share/zoneinfo/Europe/Amsterdam

# Configure time, locale etc.
timedatectl set-ntp true
ln -sf ${timezn} /etc/localtime
hwclock --systohc
echo "LANG=${locale}" > /etc/locale.conf
(cat /etc/locale.gen | grep -q "#${locale}") && sed -i "/#${locale}/s/^#//g" /etc/locale.gen && locale-gen

# Setting hostname
echo ${hostnm} > /etc/hostname

# Adding a simple user
useradd -m -G wheel -s /bin/zsh ${usernm}

# Giving the wheel group sudo privileges (without password, insecure!)
sed -i "/# %wheel ALL=(ALL) NOPASSWD/s/^# //g" /etc/sudoers

# Adding colors to pacman
grep -q "^Color" /etc/pacman.conf || sed -i "s/^#Color$/Color/" /etc/pacman.conf

# Disabling annoying system beep sound
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;

# Stowing dotfiles
pacman -S --noconfirm --needed stow
stow --target=/home/${usernm}/ --no-folding *

# Installing basic packages
pacman -S --noconfirm --needed $(cat basicpkg)

# Installing paru - AUR helper
git clone https://aur.archlinux.org/paru.git
cd paru
sudo -u ${usernm} makepkg --noconfirm -si
cd ..; rm -rf paru

sudo -u ${usernm} paru -S --noconfirm --needed $(cat aurpkg)

# ... custom dwm setup installation etc.
# WIP

# Enabling daemons
systemctl enable NetworkManager
