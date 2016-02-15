#!/bin/bash
#0. Prepare passwords for your clients and a PEM password
#1. Put this script in a new, empty directory directory
#2. Set the variables
#3. Launch script

#Variables:
##Server name
servername="MyServer"
##Clients with password
clientsnamesec="Client_01  Client_02  Client_03"
##Clients without password (servers and mobiles)
clientsnamenonsec="otherserver mymobile"
## server's listening ip address
serverlistip="192.168.0.2"
##public IP where the clients try to connect to
serverip="1.2.3.4"
##server's port
serverport="1194"
##LAN range to route
lanrange="172.28.25.0"
##ip from local lan dns
dnsip="172.28.25.1"
##bits - don't change unless sure
biits="4096"



#Script starts here
red=$(tput bold;tput setaf 1)
reset=$(tput sgr0)
#getting easyrsa
git clone git://github.com/OpenVPN/easy-rsa
#changing key to 4096
sed -i -e "s/\#set_var EASYRSA_KEY_SIZE\t2048/set_var EASYRSA_KEY_SIZE\t$biits/" easy-rsa/easyrsa3/vars.example
mv easy-rsa/easyrsa3/vars.example easy-rsa/easyrsa3/vars
#spawn needed directories
mkdir server clients
cp -R easy-rsa/easyrsa3/* clients/
cp -R easy-rsa/easyrsa3/* server/

#generate client pki and requests
cd clients
./easyrsa init-pki
echo "${red}Clients passwords will be asked here${reset}"
for i in $clientsnamesec
do 
	./easyrsa gen-req $i
done
for i in $clientsnamenonsec
do 
	./easyrsa gen-req $i nopass
done

#generate server pki and request
cd ../server
./easyrsa init-pki
echo "${red}PEM password will be asked here${reset}"
./easyrsa build-ca
./easyrsa gen-req $servername nopass
echo "${red}PEM password will be asked here${reset}"
./easyrsa sign-req server $servername
#Generate a DH parameter and a ta.key
openssl dhparam -out dh$biits.pem $biits
/usr/sbin/openvpn --genkey --secret ta.key
#Import and sign all our clients requests
echo "${red}Say yes, and give PEM password for EACH client${reset}"
for cliient in $(ls ../clients/pki/reqs/|sed -e 's/.req//g'); do
	./easyrsa import-req ../clients/pki/reqs/$cliient.req $cliient
	./easyrsa sign-req client $cliient
done

cd ../
#populate dedicated dirs for each client
for cliient in $(ls clients/pki/reqs/|sed -e 's/.req//g'); 
do
        if [[ ! -d keys/$cliient ]]; then
                mkdir -p keys/$cliient/keys
        fi
        cp server/dh$biits.pem keys/$cliient/keys/
        cp server/ta.key keys/$cliient/keys/
        cp server/pki/ca.crt keys/$cliient/keys/
        cp server/pki/issued/$cliient.crt keys/$cliient/keys/client.crt
        cp clients/pki/private/$cliient.key keys/$cliient/keys/client.key
        echo -e "client\nremote $serverip $serverport\nproto udp\ndev tun0\nkeepalive 10 120\nnobind\npersist-key\npersist-tun\ncipher BF-CBC\nca keys/ca.crt\ncert keys/client.crt\nkey keys/client.key\ndh keys/dh$biits.pem\ntls-auth keys/ta.key 1\nremote-cert-tls server\ncomp-lzo\nstatus openvpn-status.log\nverb 1\nlog openvpn.log">keys/$cliient/client.conf
        echo -e "client\nremote $serverip $serverport\nproto udp\ndev tun0\nkeepalive 10 120\nnobind\npersist-key\npersist-tun\ncipher BF-CBC\nremote-cert-tls server\ncomp-lzo\nstatus openvpn-status.log\nverb 1\nlog openvpn.log\n<ca>">keys/$cliient/cliandroid.ovpn
        cat keys/$cliient/keys/ca.crt >> keys/$cliient/cliandroid.ovpn
        echo -e "</ca>\n<cert>">> keys/$cliient/cliandroid.ovpn
        cat keys/$cliient/keys/client.crt >> keys/$cliient/cliandroid.ovpn
        echo -e "</cert>\n<key>">> keys/$cliient/cliandroid.ovpn
        cat keys/$cliient/keys/client.key >> keys/$cliient/cliandroid.ovpn
        echo -e "</key>\n<dh>">> keys/$cliient/cliandroid.ovpn
        cat keys/$cliient/keys/dh$biits.pem >> keys/$cliient/cliandroid.ovpn
        echo -e "</dh>\nkey-direction 1\n<tls-auth>">> keys/$cliient/cliandroid.ovpn
        cat keys/$cliient/keys/ta.key >> keys/$cliient/cliandroid.ovpn
        echo "</tls-auth>">> keys/$cliient/cliandroid.ovpn
done

#populate dedicated dir for server
for serveer in $(ls server/pki/private/|grep -v ca.key|sed -e 's/.key//g');
do
        if [[ ! -d keys/$serveer ]]; then
                mkdir -p keys/$serveer/keys
        fi
        cp server/dh$biits.pem keys/$serveer/keys/
        cp server/ta.key keys/$serveer/keys/
        cp server/pki/ca.crt keys/$serveer/keys/
        cp server/pki/issued/$serveer.crt keys/$serveer/keys/client.crt
        cp server/pki/private/$serveer.key keys/$serveer/keys/client.key
        echo -e "local $serverlistip\nport $serverlistport\nproto udp\ndev tun1\ndaemon\nca /etc/openvpn/$serveer/keys/ca.crt\ncert /etc/openvpn/$serveer/keys/$serveer.crt\nkey /etc/openvpn/$serveer/keys/$serveer.key\ndh /etc/openvpn/$serveer/keys/dh$biits.pem\ntls-auth /etc/openvpn/$serveer/keys/ta.key 0\nserver 10.5.2.0 255.255.255.0\nifconfig-pool-persist ipp.txt\npush \"route $lanrange 255.255.255.0\"\npush \"dhcp-options DNS $dnsip\"\nkeepalive 10 120\ncipher BF-CBC\ncomp-lzo\nmax-clients 10\nuser _openvpn\ngroup _openvpn\npersist-key\npersist-tun\nstatus openvpn-status.log\nlog         openvpn.log\nverb 2\n" >keys/$serveer/$serveer.conf
done
