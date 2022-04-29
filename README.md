﻿# ComfyDots — My comfortable dotfiles

This repository includes a collection of my personal dotfiles, other configurations and scripts I use on my desktop. However, even though I consider these files 'comfy' for me right now, it's certainly not optimal or finished, and thus, always changing.

## About
I use this repository as a way to version control my setup and keep track of changes, so I don't lose any of the configurations I want to keep. I've also included a *configuration script*, which performs tasks I normally do while installing Arch Linux. Even though this script also deploys my dotfiles, you should not consider it as a full bootstrap script, but rather as another way to keep track of the various things I normally want to do while installing my desktop. I use my dotfiles in combination with my builds of [dwm](https://github.com/consoom/dwm), [dwmblocks](https://github.com/consoom/dwmblocks) and st.

## Dotfiles installation
My dotfiles are supposed to be managed with [GNU stow](https://www.gnu.org/software/stow/). I have a copy of this repository stored in *~/.local/share/comfydots*, and in combination with stow, you can automatically create symlinks to the appropriate locations in the home directory, which I try to keep as clean as possible. It's visually represented like this: (example)
```
comfydots		   ← (this repo)
│
└── xorg                   ← (name of the stow 'package' - not actually anything in ~/)
│   └─ .config
│       └─ xorg
│           |── Xresources ← (will point to ~/.config/xorg/Xresources)
│           |── xinitrc    ← (will point to ~/.config/xorg/xinitrc)
│
└── zsh                    ← (name of the stow 'package' - not actually anything in ~/)
│   └─ .config
│       └─ zsh
│           |── .zshrc     ← (will point to ~/.config/zsh/.zshrc)
...
```
Using stow, you can choose to install a 'stow package', which then will create symlinks to all files inside of it to a location you specify, which probably will be your home directory.
For example, to install my zsh configuration, run: `$ stow --target=/home/$USER/ --no-folding zsh`. In the case of this command, it will symlink every file in the zsh package (so the .zshrc file) to it's respective location, just like how it is in the hierarchy of the stow package. This means that the .zshrc file will be placed at *~/.config/zsh/.zshrc*.
You can also delete it by running: `$ stow --target=/home/$USER/ -D zsh`.
To learn more about stow, you could for example read [this article](https://web.archive.org/web/20210515192752/https://alexpearce.me/2016/02/managing-dotfiles-with-stow/).

## Configuration script
I've also created a [configuration script](conf.sh), which on top of automatically deploying my dotfiles with stow, also installs packages that I frequently use. It also performs some basic commands I commonly use on a fresh *Arch Linux* installation, like adding a new user and setting the timezone. It does *not* help you partition your system nor configures your bootloader, as it's not meant to be a bulletproof bootstrap script. That's why I don't recommend anyone running it, but it might be useful for some to get inspiration out of.
To use it, you have to edit the script to change some parameters, like your desired username and language, and then run it inside of a freshly pacstrapped arch-chroot environment. It does not install any of my graphical programs for now.

## Screenshot
![enter image description here](https://user-images.githubusercontent.com/33983173/166064884-fd3c6e0d-744d-4899-a680-dd997b72283b.png)
