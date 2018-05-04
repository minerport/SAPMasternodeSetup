#!/bin/bash
# METHUSELAH Masternode Setup Script V1.3 for Ubuntu 16.04 LTS
# (c) 2018 by Dwigt007 for Methuselah
#
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash sap-setup.sh [Masternode_Private_Key]
#
# Example 1: Existing genkey created earlier is supplied
# bash sap-setup.sh 27dSmwq9CabKjo2L3UD1HvgBP3ygbn8HdNmFiGFoVbN1STcsypy
#
# Example 2: Script will generate a new genkey automatically
# bash sap-setup.sh
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Methuselah TCP port
PORT=7555

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'methuselahd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop methuselahd${NC}"
        methuselah-cli stop
        delay 30
        if pgrep -x 'methuselah' > /dev/null; then
            echo -e "${RED}methuselahd daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill methuselahd
            delay 30
            if pgrep -x 'methuselahd' > /dev/null; then
                echo -e "${RED}Can't stop methuselahd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear

echo -e "
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNXK0Okkxdolc:::::::::cclodxkOO0KXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNKOxoc;,...                         ...',:ldk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxl;'..                                          ..':ok0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0ko;..                                                      .'cdOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKkl,.                      ...................                      ..;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.                 ..';cloxkO0KKKXXXXXXXXXKKKK0Okdoc:,..                 .'ckKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0d;.              ..,:oxO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kdl:'.               .:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWKx;.             .'cdOXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNKko;..             .lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMN0l'            .'cd0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXOo;.            .,dKWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMNk;.           .;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkl'            .c0WMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMWXx;.          .;d0NMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXNWWXOl'.          .cONMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNx,           'l0NWMWXkl,,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c',lOXWWXk:.          .cOWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNk;          .;xKWMMNOl'.  .:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,.  .,o0NWN0o'          .l0WMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMW0c.         .:ONMMWKd;.  .,oONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl,.  .:xXWWXx,          'dXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMXd'         .:ONMMW0o'   'lONWWNKkldKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdld0NWMWNOc.   'oKWWXx,.         ;ONMMMMMMMMMMMMMMMM
MMMMMMMMMMMMW0:.        .;ONMMW0l.  .;xKWMWKx:.  .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.  .,o0NMMWKd,   'oKWWXd'         .oXMMMMMMMMMMMMMMM
MMMMMMMMMMMNx'         'dXMMWKo.  .:kXWMNOl'   .:dKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl'   .;xXMMWXx,   'dKWWKc.         :0WMMMMMMMMMMMMM
MMMMMMMMMMXo.        .lKWMMXd'  .;OWMWXx;.  .;dKWMMMWNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXWMMMWXkc.   'o0WMMXx,   ,xNMNk;         'kWMMMMMMMMMMMM
MMMMMMMMMKc.        'xNMMWO:.  ,xNMWXx,   'lONMMMWXkl;'c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.':d0NWMMWKd;.  .l0WMWXd'  .c0WWXo.        .dNMMMMMMMMMMM
MMMMMMMW0:         ;0WMMNx.  .lKWMNx;.  'dKWMMMNOc'   .;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c.   .;dKWMMMNk:.  .oXMMW0c.  'xNMNx'        .oXMMMMMMMMMM
MMMMMMW0:        .cXMMWKc.  ,kNMWO:.  'dXMMMWKd,.  .;oOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'   .cONMMMNk;.  ,xNMMNx,  .lXWWO;        .oXMMMMMMMMM
MMMMMMK:        .lXMMWO;  .cKWWXd.  .lKWMMW0l.   ,o0NWMMNKkoxKWMMMMMMMMMMMMMMMMMMMMMMWXxld0XWMMWXx:.  .:kNMMMXx'  .c0WMW0:  .cKWW0;        .dNMMMMMMMM
MMMMWXc        .oXMMWk,  .oXMW0:.  ;kNMMWKl.  .;xXWMWN0d;.  .cXMMMMMMMMMMMMMMMMMMMMMMNd.  .'ckXWMMN0l.  .:kNMMWKc.  'kWMMXl.  :0WWK:        .dNMMMMMMM
MMMMNo.       .oXMMMO'  .dNMWk,  .lKWMMNx'  .:kNMMWKd;.   .:d0WMMMMMMMMMMMMMMMMMMMMMMWXkl,.   'lONMMW0l.  .cKMMMNx'  .dNMMXo.  ;0MMK:        .kMMMMMMM
MMMNx.       .lXMMWO,  .xNMWx.  'xNMMW0c.  ,xNMMW0l'   'ckXWMMMMMWWMMMMMMMMMMMMMMWWWMMMMWN0o,.  .:kNMMW0:.  ,kNMMWO;  .oXMMXo.  ;0MW0,        ;0MMMMMM
MMW0;        :KWMWK;  .dNMNx.  'kWMMNk'  .lKWMWKo.  .;xKWMMMMWXOdlo0WMMMMMMMMMMW0ocokKNWMMMWNOc.  .:ONMMNx'  .oXWMW0;  .lXMMXl.  cKMWk'        lNMMMMM
MMXo.       'kWMMXl. .lXMWk'  'kWMMNx'  'xNMMNx,  .;kNMMMMWKxc'.   :KWMMMMMMMMMXl.   .,oONMMMMN0l.  .oKMMW0;  .lXMMW0;  .dNMMK:  .oNMXo.       'kWMMMM
MWO,       .oNMMNd.  ;0WW0,  .xWMMNd.  'kWMWKl.  ,xXMMMMNOc.   .;lx0WMMMMMMMMMMWXOoc'.  .;xXWMMMWO:.  ;OWMWK:  .cXMMMO,  .kWMWO'  'kWWK:        cKWMMM
MXl.       ,OMMM0;  .kWMXc  .oXMMWx.  'kWMW0:  .c0WMMMNO:.  .;d0NWMMMWNNXXXXXNWMMMMWXkl'   ,dXMMMMXo.  'kWMWKc  .lXMMWk.  ;0WMNd.  :XMNd.       .kWMMM
M0,       .dWMMNd.  cNMNx.  :KMMWO'  'kWMMWk. .oXMMMWKl.  .cONMMMWXkdc;'....',:ox0NMMMWKd'  .;OWMMMNx, .oNMMW0:  .dNMMXl.  lNMMX:  .xNMX:        cXMMM
Wx.       'OMMM0;  .kWMK;  .xNMMX:  .dNMMMMNOdONMMMW0;  .:OWMMWXk:.    .......   .;dKWMMMXl.  'xNMMMWKxONMMMMWk'  ,OWMW0;  'OWMNx.  :KMWd.       ,0MMM
Nl.      .lXMMMk.  cXMNx.  :KWMNx.  :KMMMMMMMMMMMMWO,  .oXMMMNx;.  .;ok0KKKKKOdc'.  .oKWMMNx'  .dNMMMMMMMMMMMMXl. .lXMMXo. .oNMW0;  '0MW0,       .kWMM
K:       .xWMMWx. .dWMXc. .xNMMKc  .xNMMMMMMMMMMMW0;  .dNMMWKl.  'o0NMMMMMMMMMMWXk:.  ,kWMMWO'  'kWMMMMMMMMMMMMO'  ,0WMWO'  ;0WMNl. .kWMNl       .dNMM
O'       .OMMMNo. .kMM0;  'kWMWO'  ;KMMMMMMMMMMMMNd.  lNMMMXc  .c0WMMWXOxdxkOXWMMMNx.  'kWMMWx.  lXMMMMMMMMMMMMXl. .dWMMK:  .xNMWx. .dNMWo        cXMM
x.       '0MMMXc  ,0MMO'  ;0WMNx.  cXMMMMMMMMMMMMWKo,c0WMMNd.  cKMMW0l'......'lKWMMWx.  ;KMMMNd;l0WMMMMMMMMMMMMWx.  cNMMXc  .dNMWk' .lXMWd.       ,0MM
d.       ,0MMMK:  :KMWk.  cXMMNd. .oNMMMMMMMMMMMMMMWNNMMMMX;  'OWMW0; .lk0kxc. ;0MMMXl. .dWMMMWNWMMMMMMMMMMMMMMMO.  :XMMNo. .dNMWO, .cXMMx.       '0MM
d.       ;0MMMK:  :KMWx.  cXMMNo. .xNMMMMMMMMMMMMMMMMMMMMMK,  ,KMMWo..cXMMMMK: .xWMMNd.  oWMMMMMMMMMMMMMMMMMMMMMO.  :XMMNo. .dNMWO, .lXMMx.       '0MM
d.       ,0MMMXc. :KMWk.  cKMMNo. .dNMMMMMMMMMMMMMMMMMMMMMX:  .kWMWO' .o0K0Oo. ,OMMMXc. .xWMMMMMMMMMMMMMMMMMMMMMO.  :XMMNl. .dNMWO, .oXMMx.       '0MM
x.       '0MMMNo. ,0MMO,  ;0WMNd.  lXMMMMMMMMMMMMMMMMMMMMMNx.  ;0WMWO:........c0WMMNd.  :KMMMMMMMMMMMMMMMMMMMMMWk.  cXMMXc  .dNMWk' .dNMMd.       ,0MM
O'       .OMMMWx. .kMM0;  'kWMWk.  :XMMMMMMMMMMMMMMMMMMMMMMXo.  ;kNMMN0xolodkKNMMWXo.  ,OWMMMMMMMMMMMMMMMMMMMMMXo. .oNMMK;  'kWMWx. .kWMMd        :KMM
0;       .kMMMMk. .dWMXl. .dNMW0;  'OWMMMMMMMMMMMMMMMMMMMMMMNd.  .ckXWMMMMMMMMMWKd,   ;OWMMMMMMMMMMMMMMMMMMMMMM0,  ,OWMNx.  :KMMNl. 'OMMWl       .lXMM
Xl.      .oNMMMO.  cNMWk.  :KWMNo. .cXMMMMMMMMMMMMMMMMMMMMMMMWOc.  .'coxO0OOkdl;.   'dXMMMMMMMMMMMMMMMMMMMMMMMNd.  cXMMXl. .oNMWK;  '0MMK;       .xNMM
Wd.       ;0MMM0;  'kWMK;  .xNMW0,  'kWMMMMMMMMMMMMMMMMMMMMMMMMN0o;.     .      ..ckXWMMMMMMMMMMMMMMMMMMMMMMMWO,  'kWMWO,  ,0WMWx.  :KMWx.       'OWMM
Mk'       .xWMMNd.  cNMNk.  :KMMWd.  :0MMMMMMMMMMMMMMMMMMMMMMMMMMMNKkdc:;;;;;:lxOXWMMMMMMMMMMMMMMMMMMMMMMMMMMXc. .oXMMXc. .oNMMX:  .xNMNl        :KMMM
MKc        :KMMW0;  'kWMNl  .lXMMNl. .cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.  :KMMNx.  :XMMNx.  :XMWk'       .dNMMM
MWx.       .dWMMNd.  :KWW0;  .xNMMK:  'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  ;0MMWk.  'OMMM0,  'kWMXc        ;0WMMM
MMKc.       ;0WMMXc  .lXMWk'  .xNMMKc.;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl.c0WMWO,  .xWMMKc. .oNMNx.       .dNMMMM
MMWO'       .lXMMW0;  .dNMWk'  .xNMMN0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXKNMMWk'  .dNMMXl.  cKMW0;        :KMMMMM
MMMNo.       .dNMMWO,  .xNMWx'  .dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk'  .dNMMNd.  ;0MMKc.       'kWMMMMM
MMMMX:        .kNMMWk'  .dNMWO;  .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.  'kNMMNo.  ;OWMXl.       .dWMMMMMM
MMMMWO,        'kWMMWk'  .dXMW0c.  ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNO;   :0WMMXl.  ;0WMNo.       .lXMMMMMMM
MMMMMWO,        'xNMMWO;  .cKWWXd.  .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.  .oXMMW0:   :0WMXl.       .cKMMMMMMMM
MMMMMMWk'        .xNMMWKc.  ;OWMW0:.  ;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl  .:OWMMNk,  .lKWMXl.        :0WMMMMMMMM
MMMMMMMWx'        .oXWMMXd.  .oXMMNx;'cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd,:xXWMMKl.  'xNMW0:         :0WMMMMMMMMM
MMMMMMMMWk,         cKWMMWO;   ,kNMMNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWMMWXx'  .:0MMWk,         cKWMMMMMMMMMM
MMMMMMMMMW0:         ,xNMMMXd.  .:ONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;.  ,xNMWKo.        .oXMMMMMMMMMMMM
MMMMMMMMMMWKl.        .c0WMMW0l.  .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXk:.  .dKWMNk,         'dNMMMMMMMMMMMMM
MMMMMMMMMMMMNx'         .dXMMMW0l.  .;xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXx;.  .lKWMW0c.         ;OWMMMMMMMMMMMMMM
MMMMMMMMMMMMMW0:.         ,xXWMMW0l.  .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl   'oKWMW0o.         .oXMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMXx,          ,xXWMMWKd;,xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd';xKWMWKl.         .:OWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWKl.          ,dKWMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMNOl.          'xNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMW0c.          .cONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx;.          .oXWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMNO:.          .;d0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl'           'oKWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMN0l.           .;o0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'.           'dKWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMW0o,            .,lxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOd:'            .;xXWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWXk:.             .;lk0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXOdc,.             'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKd;.              .':ox0XNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKOdl;..              .ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.                ..,;coxO0KXNWMMMMMMMMMMMMMMMWWNX0Okxo:;'..                'cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                    ...,;;;:::cccccc:::;;,'...                    .,lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0dc,.                                                         ..;lxKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKko:,.                                                .;cdOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0Oxlc;...                                ..';coxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNXKOkdolcc:;,'............',;:clodxk0KXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXXXKKKKKXXXXNNNWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
"
delay 5
echo -e "${YELLOW}METHUSELAH Masternode Setup Script V1.3 for Ubuntu 16.04 LTS${NC}"
echo -e "${GREEN}Updating system and installing required packages...${NC}"
sudo DEBIAN_FRONTEND=noninteractive apt-get update -y

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR:${YELLOW} Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR:${YELLOW} Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi

# update packages and upgrade Ubuntu
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev

sudo apt -y install software-properties-common
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev

sudo apt-get -y install libminiupnpc-dev

sudo apt-get -y install fail2ban
sudo service fail2ban restart

sudo apt-get install ufw -y
sudo apt-get update -y

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow $PORT/tcp
sudo ufw allow 7556/tcp
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"

#Generating Random Password for methuselahd JSON RPC
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if grep -q "SwapTotal" /proc/meminfo; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img 2> /dev/null
    swapon /var/swap.img 2> /dev/null
    if [ $? -eq 0 ]; then
        echo '/var/swap.img none swap sw 0 0' >> /etc/fstab
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${YELLOW}Operation not permitted! Optional swap was not created.${NC} \a"
        rm /var/swap.img
    fi
fi

#Installing Daemon
cd ~
#sudo rm methuselah-1.0.1.0-linux.tar.gz
#wget https://github.com/methuselah-coin/methuselah/releases/download/v1.0.1.0/methuselah-1.0.1.0-linux.tar.gz
#sudo tar -xzvf methuselah-1.0.1.0-linux.tar.gz --strip-components 1 
#sudo rm methuselah-1.0.1.0-linux.tar.gz

stop_daemon

# Deploy binaries to /usr/bin
sudo cp SAPMasternodeSetup/methuselah-1.0.1.0-linux/methuselah* /usr/bin/
sudo chmod 755 -R ~/SAPMasternodeSetup
sudo chmod 755 /usr/bin/methuselah*

# Deploy masternode monitoring script
cp ~/SAPMasternodeSetup/nodemon.sh /usr/local/bin
sudo chmod 711 /usr/local/bin/nodemon.sh

#Create methuselah datadir
if [ ! -f ~/.methuselah/methuselah.conf ]; then 
	sudo mkdir ~/.methuselah
fi

echo -e "${YELLOW}Creating methuselah.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.methuselah/methuselah.conf
rpcuser=rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.methuselah/methuselah.conf

    #Starting daemon first time just to generate masternode private key
    methuselahd -daemon
    delay 30

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(methuselah-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR:${YELLOW}Can not generate masternode private key.$ \a"
        echo -e "${RED}ERROR:${YELLOW}Reboot VPS and try again or supply existing genkey as a parameter."
        exit 1
    fi
    
    #Stopping daemon to create methuselah.conf
    stop_daemon
    delay 30
fi

# Create methuselah.conf
cat <<EOF > ~/.methuselah/methuselah.conf
rpcallowip=127.0.0.1
rpcuser=rpcuser
rpcpassword=$rpcpassword
server=1
daemon=1
listen=1
rpcport=7556
onlynet=ipv4
maxconnections=64
masternode=1
masternodeprivkey=$genkey
externalip=$publicip
promode=1
EOF

#Finally, starting methuselah daemon with new methuselah.conf
methuselahd
delay 5

#Setting auto star cron job for methuselahd
cronjob="@reboot sleep 30 && methuselahd"
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
    echo $cronjob >> tempcron
    crontab tempcron
fi
rm tempcron

echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$publicip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your Methuselah collateral funds):
======================================================================== \a"
echo -e "${YELLOW}mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}mn1${NC} - with your desired masternode name (alias)
    ${YELLOW}TxId${NC} - with Transaction Id from masternode outputs
    ${YELLOW}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the Methuselah network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}masternode start-alias mn1${NC}
    where ${YELLOW}mn1${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!
Currently your masternode is syncing with the Methuselah network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in methuselah.conf:
${YELLOW}cat ~/.methuselah/methuselah.conf${NC}
Here is your methuselah.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat ~/.methuselah/methuselah.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit methuselah.conf, first stop the methuselahd daemon,
then edit the methuselah.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the methuselahd daemon back up:
to stop:   ${YELLOW}methuselah-cli stop${NC}
to edit:   ${YELLOW}nano ~/.methuselah/methuselah.conf${NC}
to start:  ${YELLOW}methuselahd${NC}
========================================================================
To view Methuselah debug log showing all MN network activity in realtime:
${YELLOW}tail -f ~/.methuselah/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:
${YELLOW}nodemon.sh${NC}
or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================
Enjoy your Methuselah Masternode and thanks for using this setup script!

If you found this script useful, please donate to : MfTVeFzu3oJNnrDxABoguhLcnv4scfFBtK
...and make sure to check back for updates!
Authors: Allroad [fasterpool] , Dwigt007
"
delay 30
# Run nodemon.sh
nodemon.sh

# EOF
