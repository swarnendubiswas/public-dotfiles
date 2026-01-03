#!/usr/bin/env bash

# Useful Kubuntu (w/ KDE Plasma) PPAs

set -eux

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root!"
    exit 1
fi

add-apt-repository ppa:agornostal/ulauncher -y
add-apt-repository ppa:alexlarsson/flatpak -y
add-apt-repository ppa:appimagelauncher-team/stable -y
add-apt-repository ppa:apt-fast/stable -y
add-apt-repository ppa:aslatter/ppa -y
add-apt-repository ppa:fish-shell/release-3 -y
add-apt-repository ppa:gerardpuig/ppa -y
add-apt-repository ppa:graphics-drivers/ppa
add-apt-repository ppa:inkscape.dev/stable -y
add-apt-repository ppa:joe-yasi/amarok-kde5 -y
add-apt-repository ppa:kubuntu-ppa/ppa -y
add-apt-repository ppa:kubuntu-ppa/backports -y
add-apt-repository ppa:kubuntu-ppa/backports-extra -y
add-apt-repository ppa:libreoffice/ppa -y
add-apt-repository ppa:linrunner/tlp -y
add-apt-repository ppa:mozillateam/ppa -y
add-apt-repository ppa:numix/ppa -y
add-apt-repository ppa:ozmartian/apps -y
add-apt-repository ppa:papirus/papirus -y
add-apt-repository ppa:peterlevi/ppa -y
add-apt-repository ppa:shutter/ppa -y
add-apt-repository ppa:stk/dev -y
add-apt-repository ppa:ubuntuhandbook1/gimp -y
add-apt-repository ppa:ubuntu-mozilla-security/ppa -y
add-apt-repository ppa:zanchey/asciinema -y
add-apt-repository ppa:zhangsongcui3371/fastfetch -y

curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

wget -qO - https://apt.packages.shiftkey.dev/gpg.key | gpg --dearmor | tee /usr/share/keyrings/shiftkey-packages.gpg >/dev/null
sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/shiftkey-packages.gpg] https://apt.packages.shiftkey.dev/ubuntu/ any main" > /etc/apt/sources.list.d/shiftkey-packages.list'

# https://www.fortinet.com/support/product-downloads/linux
wget -O - https://repo.fortinet.com/repo/forticlient/7.4/ubuntu22/DEB-GPG-KEY | gpg --dearmor | tee /usr/share/keyrings/repo.fortinet.com.gpg
sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/repo.fortinet.com.gpg] https://repo.fortinet.com/repo/forticlient/7.4/ubuntu22/ stable non-free" > /etc/apt/sources.list.d/repo.fortinet.com.list'

set +eux
