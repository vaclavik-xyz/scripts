#!/bin/sh
# script to setup fresh openSUSE install

# Test to see if user is running with root privileges.
if [[ "${UID}" -ne 0 ]]
then
 echo 'Must execute with sudo or root' >&2
 exit 1
fi

# update repos and packages
zypper dup -y

# install essentials
zypper install -y git make wget curl opi flatpak

# add brave repo
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
zypper addrepo https://brave-browser-rpm-release.s3.brave.com/x86_64/ brave-browser
# add packman repo
zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
# add flatpak flathub repo
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# refresh all repos and automatically accept all GPG keys
zypper --gpg-auto-import-keys ref

# update
zypper dup -y

# install codecs from packman
zypper install -y --from packman ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec-full vlc-codecs

# install other packages
zypper install -y qbittorrent vim tmux vlc zsh flatpak lollypop tor torbrowser-launcher brave-browser neofetch libvulkan_intel libvulkan_intel-32bit steam wine gnome-boxes lutris speedtest-cli autoconf automake sassc pkg-config optipng inkscape gtk3-devel gtk2-engine-murrine gimp libreoffice stow

# install flatpaks
flatpak install -y flathub com.discordapp.Discord com.github.tchx84.Flatseal com.microsoft.Teams com.skype.Client com.spotify.Client com.github.johnfactotum.Foliate com.bitwarden.desktop com.github.maoschanz.drawing

# set hostname
echo "x230" > /etc/hostname

# deploy dotfiles with stow (only folders, omits other files - readme.md, etc.)
stow -t ~ */

# change shell to zsh
# chsh -s /bin/zsh $SUDO_USER

# remove unused software
zypper remove -y gnome-music gnome-software PackageKit


# disable PackageKit systemd service (systemctl disable & stop combined)
sudo systemctl disable --now packagekit
