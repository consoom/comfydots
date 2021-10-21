#!/bin/bash

# Simple configuration script that executes common commands for a plain & basic setup.
# NOTE: this is a personal script for my specific use case, requires manual tinkering.

# Variables/settings
hostnm=comfy
usernm=joe
locale=en_US.UTF-8
timezn=/usr/share/zoneinfo/Europe/Amsterdam

archchrootsetup () {
	# Install prompt
	echo -e "\nYou are about to setup a basic system (set timezone, install packages, create a new user, etc.)"
	echo "This script will NOT handle bootloaders or fstab - as that differs from scenario."
	echo "Please make sure you are running this inside of a chroot environment."
	echo -e "After the script has finished, you may delete this repo in this current directory.\n"
	echo "--- Current settings: (edit in script)"
	echo "Hostname: ${hostnm}"
	echo "Username: ${usernm}"
	echo "Locale: ${locale}"
	echo -e "Timezone: ${timezn}\n"
	while true; do
		read -p "Do you wish to continue the setup? (y/n)" yn
    		case $yn in
        		[Yy]* ) break;;
        		[Nn]* ) exit;;
        		* ) echo "Please answer with yes or no.";;
    		esac
	done

	# Configure time, locale etc.
	timedatectl set-ntp true
	ln -sf ${timezn} /etc/localtime
	hwclock --systohc
	echo "LANG=${locale}" > /etc/locale.conf
	(cat /etc/locale.gen | grep -q "#${locale}") && sed -i "/#${locale}/s/^#//g" /etc/locale.gen && locale-gen

	# Setting hostname
	echo ${hostnm} > /etc/hostname

	# Add matching entries to hosts if not already done
	(cat /etc/hosts | grep -q "127.0.0.1") || echo "127.0.0.1	localhost" >> /etc/hosts
	(cat /etc/hosts | grep -q "::1") || echo "::1		localhost" >> /etc/hosts
	(cat /etc/hosts | grep -q "127.0.1.1") || echo "127.0.1.1	${hostnm}" >> /etc/hosts

	# Adding a simple user
	useradd -m -G wheel -s /bin/zsh ${usernm}
	
	# Installing basic packages
	pacman -S --noconfirm --needed $(cat basicpkg)

	# Giving the wheel group sudo privileges (without password, insecure!)
	sed -i "/# %wheel ALL=(ALL) NOPASSWD/s/^# //g" /etc/sudoers

	# Adding colors to pacman
	grep -q "^Color" /etc/pacman.conf || sed -i "s/^#Color$/Color/" /etc/pacman.conf

	# Disabling annoying system beep sound
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;

	# Enabling daemons
	systemctl enable NetworkManager

	# Cloning this repo inside of the home folder of the new user
	dotfilesdir=/home/${usernm}/.local/share/comfydots
	su -c "mkdir -p ${dotfilesdir}" ${usernm}
	cp -R $(dirname "$0") ${dotfilesdir}; chown -R ${usernm}: ${dotfilesdir}
	su -c "/home/${usernm}/.local/share/comfydots/conf.sh postsetup" ${usernm}
	exit 1
}

postsetup () {
	cd /home/$USER/.local/share/comfydots/
	# Stowing dotfiles
	stow --target=/home/$USER/ --no-folding scripts 
	stow --target=/home/$USER/ --no-folding share
	stow --target=/home/$USER/ --no-folding shell
	stow --target=/home/$USER/ --no-folding xorg
	stow --target=/home/$USER/ --no-folding zsh

	# Symlink .zprofile in ~ to ~/.config/shell/profile
	ln -sf /home/$USER/.config/shell/profile /home/$USER/.zprofile

        # Installing paru - AUR helper
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg --noconfirm -si
        cd ..; rm -rf paru

	# Installing AUR packages
	paru -S --noconfirm --needed $(cat aurpkg)

	# Finalizing
	echo -e "\n---\nEnd of script reached. Please set passwords for both the root account and $USER:"
	echo "(as root) passwd"
	echo "(as root) passwd $USER"
}

[ "$1" == "postsetup" ] || archchrootsetup
postsetup
