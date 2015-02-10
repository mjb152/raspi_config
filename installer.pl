#!/usr/bin/env perl
use strict;
use warnings;

# Changes to be made ........  wifi goes to /etc/networks   and wpa_supplicant.conf
# script to create a new user environment for a Raspberry Pi
my $duser = 'pi';	#default user, but it can be replaced if we like

create_user(\$duser)	if (yesno("Would you like to create a replacement user for \"pi\" ?"));
configure_wifi()	if (yesno("Would you like to configure WiFi ?"));
install_nginx(\$duser)	if (yesno("Would you like to install nginx ?"));


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
        my $wpa1 = slurp('netinterfaces');
        my $wpa2 = slurp('netwpa_supplicant.conf');
	$wpa2 =~ s/XX__SSID__XX/$ssid/;
	$wpa2 =~ s/XX__PASS__XX/$pass/;
        cmd("sudo echo -e \"$wpa1\" > /etc/network/interfaces");
        cmd("sudo echo -e \"$wpa2\" > /etc/wpa_supplicant/wpa_supplicant.conf");
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

sub yesno {
  my ($query) = @_;
  my $answer = prompt("$query (y/n): ");
  return lc($answer) eq 'y';
}

sub slurp {
	my ($file) = @_;
	open my $fh, '<', $file or die;
	local $/ = undef;
	my $cont = <$fh>;
	close $fh;
	return $cont;
}
