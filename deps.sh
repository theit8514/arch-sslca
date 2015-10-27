#!/bin/bash

# exit script if return code != 0
set -e

# define pacman packages
pacman_packages="net-tools openresolv unzip unrar wget openssh nginx"

# install pre-reqs
pacman -Sy --noconfirm
pacman -S --needed $pacman_packages --noconfirm

# https://github.com/OpenVPN/easy-rsa/releases/download/3.0.1/EasyRSA-3.0.1.tgz
wget -q https://github.com/OpenVPN/easy-rsa/releases/download/$EASY_RSA_VERSION/EasyRSA-$EASY_RSA_VERSION.tgz \
 && mkdir -p /easy-rsa \
 && tar -C /easy-rsa -xvzf EasyRSA-$EASY_RSA_VERSION.tgz --strip=1 EasyRSA-$EASY_RSA_VERSION \
 && rm /EasyRSA-$EASY_RSA_VERSION.tgz \
 && chown root: /easy-rsa

# set permissions
chown -R nobody:users /home/nobody
chmod -R 775 /home/nobody

# set up openssh
mkdir /var/run/sshd
mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown -Rf root:root /root/.ssh
# generate host keys
/usr/bin/ssh-keygen -A

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
