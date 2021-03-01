#!/bin/bash
# script to setup fresh openSUSE install

# Test to see if user is running with root privileges.
if [[ "${UID}" -ne 0 ]]
then
 echo 'Must execute with sudo or root' >&2
 exit 1
fi

# Zypper global-options
ZYPPER='zypper --no-cd'

# Update repo info and update system
system_upgrade() {
    echo 'Updating repositories information...'
    $ZYPPER refresh
    echo 'Performing system upgrade...'
    $ZYPPER dup
    echo 'Done.'
    main
}

# Install official and unofficial community repositories
install_repo() {
    echo 'Installing and refreshing community repositories'

    # Packman repo
    zypper lr -u | grep -i "https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/"
    if [ $? -ne 0 ]; then
        echo 'Add Packman repository.'
        # -c check URL, -f enable automatic repo refresh, -p set priority (default 0)
        zypper ar -cfp 90 "https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/" packman
        echo 'Done.'
    fi

    # After adding packman repository be sure to switch system package to those in packman as a mix of both can cause a variety of issues.

    $ZYPPER dup --from packman --allow-vendor-change

    # Cryptocurrency repository
    zypper lr -u | grep -i "https://download.opensuse.org/repositories/network:/cryptocurrencies/openSUSE_Tumbleweed/"
    if [ $? -ne 0 ]; then
        echo 'Add Cryptocurrency repository.'
        zypper ar -cf "https://download.opensuse.org/repositories/network:/cryptocurrencies/openSUSE_Tumbleweed/" network:cryptocurrencies
        echo 'Done.'
    fi

    # Brave browser repository
    zypper lr -u | grep -i "https://brave-browser-rpm-release.s3.brave.com/x86_64/"
    if [ $? -ne 0 ]; then
        echo 'Add brave-browser repository.'
        rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
        zypper ar -cf "https://brave-browser-rpm-release.s3.brave.com/x86_64/" brave-browser
    fi

    # Refresh repositories
    echo 'Updating repositories information...'
    # refresh all repos and automatically accept all GPG keys
    $ZYPPER --gpg-auto-import-keys refresh
    main
}

install_packages() {
    $ZYPPER install $CODECS \


}



# install essentials
zypper install -y git make wget curl opi flatpak

# add flatpak flathub repo
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# install codecs from packman
zypper install -y --from packman ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec-full vlc-codecs
CODECS='--from packman ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec-full vlc-codecs'


# install other packages
zypper install -y qbittorrent vim tmux vlc zsh flatpak lollypop tor torbrowser-launcher brave-browser neofetch libvulkan_intel libvulkan_intel-32bit steam wine gnome-boxes lutris speedtest-cli autoconf automake sassc pkg-config optipng inkscape gtk3-devel gtk2-engine-murrine gimp libreoffice stow


# install flatpaks
flatpak install -y 
FLATPAK='flathub com.discordapp.Discord com.github.tchx84.Flatseal com.microsoft.Teams com.skype.Client com.spotify.Client com.github.johnfactotum.Foliate com.bitwarden.desktop com.github.maoschanz.drawing'

system_setting() {
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
}

# Exit with confirmation
bye_bye() {
	echo ''
 	read -p 'Are you sure you want to quit? (Y/n) '
 	if [ "$REPLY" == 'n' ]; then
		clear && main
 	else
	exit 12
 	fi
}


# The main function
main() {
	INPUT=0
	echo ''
	echo 'What would you like to do? (Enter the number of your choice)'
	echo ''
	while true; do
	echo '1. Perform system update ?'
	echo '2. Apply the needed patches ?'
	echo '3. Install official community repositories ?'
	echo '4. Install unofficial community repositories ?'
	echo '5. Install your favourites applications ?'
	echo '6. Install system tools applications ?'
	echo '7. Install various servers and control them with yast2 ?'
	echo '8. Install development tools ?'
	echo '9. Install virtualization tools ?'
	echo '10. Install third party applications ? (Google Chrome, Steam etc...)'
	echo '11. Cleanup the system ?'
	echo '12. Quit?'
	echo ''
	read -p 'Choose Command: ' INPUT
	case $INPUT in
		1) clear && system_upgrade ;;
	   	2) clear && system_patch ;;
	   	3) clear && install_official_repo ;;
	   	4) clear && install_unofficial_repo ;;
	   	5) clear && install_favorite_applications ;;
	    6) clear && install_system_tools ;;
	   	7) clear && install_various_servers ;;
	   	8) clear && install_devlopment_tools ;;
	   	9) clear && install_virtualization_tools ;;
	   10) clear && install_thirdparty_applications ;;
	   11) clear && clean_system ;;
	   12) bye_bye ;;
	   * ) echo 'Invalid, choose again.' && main
esac
done
}
# Run the main function
main
# End
