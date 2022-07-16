#!/bin/bash

# Simple configuration script that executes common commands for a plain & basic setup.
# NOTE: this is a personal script for my specific use case, requires manual tinkering.

# Variables/settings
hostnm=comfy
usernm=joe
locale=en_US.UTF-8
timezn=/usr/share/zoneinfo/Europe/Amsterdam

[ $PWD != "/comfydots" ] && echo -e "\n\033[38;5;1mPlease move this repository to / first.\033[0m\n" && exit

archchrootsetup () {
	# Install prompt
	echo -e "\nYou are about to setup a basic system (set timezone, install packages, create a new user, etc.)"
	echo "This script will NOT handle stuff like bootloaders, (network) deamons or fstab - as that differs from scenario."
	echo "Please make sure you are running this inside of a fresh Arch Linux installation as root."
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
	ln -sf ${timezn} /etc/localtime
	timedatectl set-ntp true
	hwclock --systohc
	echo -e "LANG=${locale}\n" >/etc/locale.conf
	(cat /etc/locale.gen | grep -q "#${locale}") && sed -i "/#${locale}/s/^#//g" /etc/locale.gen && locale-gen

	# Installing programs that are necessary for other programs to work
	pacman --noconfirm -S archlinux-keyring
	pacman --noconfirm --needed -S ca-certificates base-devel git zsh

	# Setting hostname
	echo ${hostnm} > /etc/hostname

	# Add matching entries to hosts if not already done
	(cat /etc/hosts | grep -q "127.0.0.1") || echo "127.0.0.1	localhost" >> /etc/hosts
	(cat /etc/hosts | grep -q "::1") || echo "::1		localhost" >> /etc/hosts
	(cat /etc/hosts | grep -q "127.0.1.1") || echo "127.0.1.1	${hostnm}" >> /etc/hosts

	# Adding a simple user
	useradd -m -G wheel -s /bin/zsh ${usernm}
	export repodir="/home/$usernm/.local/src"
	mkdir -p "$repodir"
	chown -R "$usernm": "$(dirname "$repodir")"
	sudo -u "$usernm" mkdir -p "/home/$usernm/.cache/zsh/"

	# Adding colors and concurrent downloads to Pacman
	grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
	sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf

	# Use all cores for compilation.
	sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

	# Disabling annoying system beep sound
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf ;

	# Allow user to run sudo without password temporary. Since AUR programs must be installed
	# in a fakeroot environment, this is required for all builds with AUR.
	trap 'rm -f /etc/sudoers.d/temp' HUP INT QUIT TERM PWR EXIT
	echo "%wheel ALL=(ALL) NOPASSWD: ALL" >/etc/sudoers.d/temp

        # Installing paru - AUR helper
	#mkdir /home/build
	#chgrp nobody /home/build
	#chmod g+ws /home/build
	#setfacl -m u::rwx,g::rwx /home/build
	#setfacl -d --set u::rwx,g::rwx,o::- /home/build
        #git clone --depth 1 --single-branch --no-tags "https://aur.archlinux.org/paru-bin.git" "/home/build"
        #cd "/home/build"
	#sudo -u nobody -D "/home/build" makepkg
	#pacman --noconfirm -U paru-bin*.zst
        #rm -rf /home/build
	#cd /comfydots
	
	sudo -u "$usernm" mkdir -p "$repodir/paru"
	sudo -u "$usernm" git -C "$repodir" clone --depth 1 --single-branch \
		--no-tags "https://aur.archlinux.org/paru-bin.git" "$repodir/paru"
	cd "$repodir/paru"
	sudo -u "$usernm" -D "$repodir/paru" makepkg --noconfirm -si
	cd /comfydots

	# Installing all packages
	
	sed '1d' packages.csv > packages_temp.csv
	while IFS=, read -r type program comment; do
        	case "$type" in
        	"A") aurpackages=$(echo "$aurpackages $program") ;;
        	"G") gitpackages=$(echo "$gitpackages $program") ;;
        	*) mainpackages=$(echo "$mainpackages $program") ;;
        	esac
	done <packages_temp.csv
	[ -z "$mainpackages" ] || pacman --noconfirm --needed -S $(echo "${mainpackages#?}")
	[ -z "$aurpackages" ] || sudo -u "$usernm" paru -S --noconfirm $(echo "${aurpackages#?}")
	
	# (HOPEFULLY TEMPORARY ADDITION!)
	# libxft-git has colored emoji support for suckless software that lacks in the stable libxft package,
	# which has to be installed explicitly for now to avoid package conflict errors.
	sudo -u "$usernm" sh -c "yes | paru -S --skipreview libxft-git"
	
	for url in ${gitpackages#?}
	do
        	progname="${url##*/}"
        	progname="${progname%.git}"
        	dir="$repodir/$progname"
        	sudo -u "$usernm" git -C "$repodir" clone --depth 1 --single-branch \
                	--no-tags "$url" "$dir"
        	cd $dir
        	make clean install
        	cd /comfydots
	done
	rm packages_temp.csv

	# Giving the wheel group sudo privileges (some commands without password)
	echo "%wheel ALL=(ALL) ALL" >/etc/sudoers.d/wheel_group
	echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/paru,/usr/bin/pacman -Syyuw --noconfirm" >>/etc/sudoers.d/wheel_group

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

	# Finalizing
	echo -e "\n---\nEnd of script reached. Please set a password for $USER:"
	echo "(as root): $ passwd $USER"
}

[ "$1" == "postsetup" ] || archchrootsetup
postsetup
