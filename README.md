# supereasyrsa
At some point I got confused and lost a couple of days in confusion using the "new" easyrsa-3 script,
then I threw together this small script to streamline the configuration of simple pki for openvpn.

Dependencies: tput openvpn openssl git

Usage:
#0. Prepare a list of users and key passwords for your clients, as well as a PEM password

#1. Put this script in an empty directory directory, dedicated to a VPN

#2. Set the variables:
Edit the variable section of the script to suit your needs
#Variables:

##Server name (name that will define your server)
servername="MyServer"

##Clients with password (list of clients, separated by a space)
clientsnamesec="Client_01  Client_02  Client_03"

##Clients without password (list servers and mobiles - separated by a space)
### note that I include mobiles here because the android version bugs when a key is password protected
### Also, beware to ensure strong security on the mobile devised with VPN installed!!!
clientsnamenonsec="otherserver mymobile"

## IP where the VPN is listening on
serverlistip="1.2.3.4"

##public IP where the clients try to connect to
serverip="1.2.3.4"

##server's listening port (port the server is listening on)
serverlistport="1194"

##port where the clients connect to
serverport="1194"

##LAN range to route
lanrange="172.28.25.0"

##ip from local lan dns (as the clients could use specific local resolving inside vpn)
dnsip="172.28.25.1"

##bits - don't change unless sure
biits="4096"

#3. Launch script - it should drive you through the generation of the keys and conf files.

#4. sorted output will be located in "keys" directory (at same level as clients and server)
