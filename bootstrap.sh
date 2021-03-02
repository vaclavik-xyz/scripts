#!/bin/bash
# script to setup fresh openSUSE install

# Test to see if user is running with root privileges.
if [[ "${UID}" -ne 0 ]]
then
    echo 'Must execute with sudo or root' >&2
    exit 1
fi

# PACKAGE GROUPS

# codecs from packman (must be run as first package group
CODECS='--from packman ffmpeg gstreamer-plugins-{good,bad,ugly,libav} libavcodec-full vlc-codecs'

# commandline packages
CLI='vim tmux zsh neofetch stow speedtest-cli'

# web packages
WEB='torbrowser-launcher brave-browser qbittorrent' 

# system packages
SYSTEM='opi libvulkan_intel libvulkan_intel-32bit'

# development packages
DEV='git make gcc curl'

# other applications
APPS='vlc lollypop steam gnome-boxes lutris libreoffice gimp'

# dependencies for solarc-theme https://github.com/schemar/solarc-theme 
SOLARC='autoconf automake sassc pkg-config optipng inkscape gtk3-devel gtk2-engine-murrine'

# install flatpaks
FLATPAK='flathub com.discordapp.Discord com.github.tchx84.Flatseal com.microsoft.Teams com.skype.Client com.spotify.Client com.github.johnfactotum.Foliate com.bitwarden.desktop com.github.maoschanz.drawing'

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
install_repos() {
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

install_flatpak() {
    echo 'Installing flatpak...'
    $ZYPPER install flatpak

    echo 'Adding flathub repo...'
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
	
	echo 'Installing flatpaks'
	flatpak install -y $FLATPAK
}

install_repo_pkgs() {
	install_repos
	$ZYPPER install $CODECS \
                    $CLI \
                    $WEB \
                    $SYSTEM \
                    $DEV \
                    $APPS \
                    $SOLARC
}

install_packages() {
	INPUT=0
 	echo ''
 	echo 'What would you like to do? (Enter the number of your choice)'
 	echo ''
 	while true; do
  		echo '1. Install repositories, all packages and all flatpaks ?'
  		echo '2. Install repositories and packages ?'
  		echo '3. Install flatpaks ?'
  		echo '4. Return'
  		echo ''
  		read -p 'Choose Command: ' INPUT

	# Install repositories, all packages and all flatpaks
  	if [ "$INPUT" -eq 1 ]; then
   	install_repo_pkgs
	install_flatpak
   	echo 'Done.'
   	install_packages

	# Install repositories and all packages
  	elif [ "$INPUT" -eq 2 ]; then
   	install_repo_pkgs
   	echo 'Done.'
   	install_packages

	# Install flatpaks
  	elif [ "$INPUT" -eq 3 ]; then
   	install_flatpak
   	echo 'Done.'
   	install_packages

	# Return
  	elif [ "$INPUT" -eq 4 ]; then
	clear && main

  	# Invalid Choice
  	else
	echo 'Invalid, choose again.'
   	install_packages
  	fi
	done
    main
}


system_settings() {
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

# Clean the system
system_cleanup() {
	INPUT=0
 	echo ''
 	echo 'What would you like to do? (Enter the number of your choice)'
 	echo ''
 	while true; do
		echo ''
		echo '1. Clean Package Cache ?'
		echo '2. Clean tildes in users home ?'
		echo '3. Return?'
		echo ''
		read -p 'Choose Command: ' INPUT

		# Clean Package Cache
		if [ "$INPUT" -eq 1 ]; then
		zypper clean --all
		echo 'Done.'
		system_cleanup

		# Clean tildes in user's home. Tilde is a backup file e.g. backup~ or .backup~
		elif [ "$INPUT" -eq 2 ]; then
		echo 'Cleaning tildes ...'
		find /home -name "*~" -exec rm -i {} \; -or -name ".*~" -exec rm -i {} \;
		echo 'Done.'
		system_cleanup
		 
		# Return to the main menu
		elif [ "$INPUT" -eq 3 ]; then
		clear && main
		 
		# Invalid Choice
		else
		echo 'Invalid, choose again.'
		system_cleanup
		fi
	done
}

# Exit with confirmation
bye_bye() {
	echo ''
 	read -p 'Are you sure you want to quit? (Y/n) '
 	if [ "$REPLY" == 'n' ]; then
		clear && main
 	else
	exit 7
 	fi
}

install_complete() {
    install_repos
    install_repo_pkgs
    install_flatpak

    main
}

# The main function
main() {
	INPUT=0
	echo ''
	echo 'What would you like to do? (Enter the number of your choice)'
	echo ''
	while true; do
	echo '1. Perform complete system install including dotfiles ?'
	echo '2. Only add repositories ?'
    echo '3. Only install packages (opt in flatpak) ?'
	#TODO echo '4. Only install dotfiles ?' 
	echo '5. Only perform system setting ?'
	echo '6. Cleanup the system ?'
	echo '7. Quit?'
	echo ''
	read -p 'Choose Command: ' INPUT
	case $INPUT in
		1) clear && system_upgrade ;;
	   	2) clear && system_patch ;;
	   	3) clear && install_packages ;;
	   	4) clear && install_unofficial_repo ;;
	   	5) clear && system_settings ;;
	    6) clear && system_cleanup ;;
	    7) bye_bye ;;
	   * ) echo 'Invalid, choose again.' && main
esac
done
}
# Run the main function
main
# End
