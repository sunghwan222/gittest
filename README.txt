About the epp-client build


This package provides the scripts to install/uninstall/update the epp-client for Linux machine.
It contains the dependencies required to install the epp-client on a Linux on both i386 and 
amd64 platforms, two bash scripts (install.sh and uninstall.sh) and a configuration file (options.ini) that 
contains the server address and the port number.


Usage:
	Install:
		Make sure you have execution rights on install.sh (chmod);
		Epp-client must not be installed at the moment of running "install.sh" (see Update);
		Set the correct IP for the server in options.ini file;
		Run as root: "./install.sh" or "bash install.sh";
		If the user is not root, the root password will be required;
		If the user is root, the epp-client GUI will have to be started manually,
		but it will start automatically at restart for the current user.
		
	Update:
		If the epp-client is already installed, the user can update the "options.ini" data
		of the current installed epp-client by overwriting it with the one provided in the 
		installation folder. This is done by running "./install.sh" or "bash install.sh"
		If the user is not root, the sudo password will be required;
		The "./install.sh" command will try to reinstall the epp-client package if it 
		encounters errors with the current installed version of epp-client.
		
	Uninstall:
		Make sure you have execution rights on uninstall.sh (chmod);
		If the user is not root, the sudo password will be required;
		If the epp-client is installed, running the "./uninstall.sh"or "bash uninstall.sh" will uninstall it;
		If the epp-client is not installed, running the command will change nothing.


Note:
	The packages that are part of this build are signed, the public key is also part of the build. Before 
        starting installation is needed to add this public key:
	As root user execute the command:

 	- RPM distros:
		for Fedora / RHEL / CentOS
		#rpm --import ./cososys_gpg2_public.key

		for SUSE/openSUSE, zypper has the ability to import gpg keys
		#zypper --gpg-auto-import refresh

	- debian distros:
		#apt-key add ./cososys_gpg2_public.key

	Regarding the new copy-paste functionality, it is supported only on X11 display servers. To check if you are running X11 or Wayland, you can run the following command in a terminal:
		$ echo $XDG_SESSION_TYPE
	which outputs either x11 or wayland. 
	In case X11 is not the display server, the functionality of copy-paste will be the old one (clipboard content that contains a threat will be erased regardless of current application)
