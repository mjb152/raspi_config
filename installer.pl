#!/usr/bin/env perl
use strict;
use warnings;

# Changes to be made ........  wifi goes to /eetc/networks   and wpa_supplicant.conf
# script to create a new user environment for a Raspberry Pi
my $duser = 'pi';	#default user, but it can be replaced if we like

create_user(\$duser)	if (prompt_yn("Would you like to create a replacement user for \"pi\" ?"));
configure_wifi()	if (prompt_yn("Would you like to configure WiFi ?"));
install_nginx(\$duser)	if (prompt_yn("Would you like to install nginx ?"));


#------------here be subprocedures--------------------------

sub create_user {
	my ($duser) = @_;
	my $username;
	print "Press CTRL-C to escape from script\n";
	until ($username) {
		$username = prompt("Please enter Username :");
	}
	
	print "Creating username $username\n";
	$$duser = $username;
	cmd("sudo useradd -m $username -G sudo");
	cmd("sudo passwd $username");
	cmd("sudo cp -r /home/pi/python_games /home/$username");
	cmd("sudo chown -R $username:$username /home/$username");
	cmd("sudo usermod -G $username,sudo,adm,video $username");
}

sub install_nginx {
	my ($duser) = @_;
	print "Installing and configuring nginx, for user $$duser\n";
	cmd("sudo chown -R $$duser:$$duser /usr/share/nginx/www");
	exit;
	cmd("sudo apt-get install nginx");
	cmd("sudo /etc/init.d/nginx start");
	cmd("sudo chown -R $$duser:$$duser /usr/share/nginx/www");
	print "Nginx config complete\n";	

}

sub configure_wifi {
        print "Configuring WiFi for first time\n";

        my $networks=qq!auto lo\niface lo inet loopback \niface eth0 inet dhcp \n \nallow-hotplug wlan0 \niface wlan0 inet dhcp \nwpa-conf /etc/wpa_supplicant/wpa_supplicant.conf \niface default inet dhcp!;
  	my $ssid = prompt("SSID = : ");
  	my $pass = prompt("PASS = : ");
        my $wpa1 = qq!ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\n\nnetwork={\nssid="$ssid"\npsk="$pass"\n\n# protocol type can be RSN (for WP2) WPA (for WPA1)\nproto=WPA\n\n!;
        my $wpa2 = qq!#key management type can be WPA-PSK or WPA-EAP (pre shared or enterprise)\nkey_mgmt=WPA-PSK\n\n#Pairwise can be CCMP or TKIP (for WPA2 or WPA1)\npairwise=TKIP\n\n# Authorization option should be OPEN for both WPA1/WPA2 (less commonly user are SSHARED and LEAP)_\nauth_alg=OPEN\n}!;
        cmd("sudo echo -e \"$wpa1\" > /home/martin/bb");
        cmd("sudo echo -e \"$wpa2\" >> /home/martin/bb");
        #sudo echo -e $NETWORKS > /etc/network/interfaces
}

sub cmd {
	my ($cmd) = @_;

	open(FH, "$cmd |") or die "Couldn't execute command $cmd\n";
	while(<FH>) {
		print;
	}
	
}

sub prompt {
  my ($query) = @_; # take a prompt string as argument
  local $| = 1; # activate autoflush to immediately show the prompt
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}

sub prompt_yn {
  my ($query) = @_;
  my $answer = prompt("$query (y/n): ");
  return lc($answer) eq 'y';
}

__END__
function sudoinstall {
        echo "Checking package status of $1"
        if [ $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed") -eq 0 ];
        then
                echo "Not installed ... installing now"
                sudo apt-get install $1;
                echo "installation complete"
        fi
}

function configure_wifi() {
        echo -e "Configuring WiFi for first time"

        NETWORKS="auto lo\niface lo inet loopback \niface eth0 inet dhcp \n \nallow-hotplug wlan0 \niface wlan0 inet dhcp \nwpa-conf /etc/wpa_supplicant/wpa_supplicant.conf \niface default inet dhcp"
        WPA1="ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\nupdate_config=1\n\nnetwork={\nssid=\"Hola Neighbourinos\"\npsk=\"hellomaldon54\"\n\n# protocol type can be RSN (for WP2) WPA (for WPA1)\nproto=WPA\n\n"
        WPA2="#key management type can be WPA-PSK or WPA-EAP (pre shared or enterprise)\nkey_mgmt=WPA-PSK\n\n#Pairwise can be CCMP or TKIP (for WPA2 or WPA1)\npairwise=TKIP\n\n# Authorization option should be OPEN for both WPA1/WPA2 (less commonly user are SSHARED and LEAP)_\nauth_alg=OPEN\n}"
        SSID=$(prompt_value "Enter Wifi SSID")
        sudo echo -e $WPA1 > /home/martin/bb
        sudo echo -e $WPA2 >> /home/martin/bb
        #sudo echo -e $NETWORKS > /etc/network/interfaces
}
