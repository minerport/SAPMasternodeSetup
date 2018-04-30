#!/bin/bash
# REDEN Masternode Setup Script V1.1 for Ubuntu 16.04 LTS

# Clears keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

clear
echo "Updating system and installing required packages..."
sudo apt-get update -y

# Install dig if it's not present
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils

echo "REDEN Masternode Setup Script V1.1 for Ubuntu 16.04 LTS"

publicip=''
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n $publicip ]; then
    echo "IP Address detected:" $publicip
else
    echo -e "ERROR: Public IP Address was not detected! \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
fi

#Reden TCP port
Port='13058'

# update packages and upgrade Ubuntu
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop git jq
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
sudo ufw allow $Port/tcp
sudo ufw --force enable


#Generating Random Password for redend JSON RPC
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
if [ ! -f /var/swap.img ]; then
    
    echo -e 'Creating 2GB disk swap file... This may take a few minutes! \a'
    touch /var/swap.img
    chmod 600 swap.img
    dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
    mkswap /var/swap.img
    swapon /var/swap.img
    echo '/var/swap.img none swap sw 0 0' >> /etc/fstab 
fi

#Installing Daemon
cd ~
#sudo rm reden_ubuntu16_1.0.0_linux.gz
#wget https://github.com/NicholasAdmin/Reden/releases/download/Wallet/reden_ubuntu16_1.0.0_linux.gz
#sudo tar -xzvf reden_ubuntu16_1.0.0_linux.gz --strip-components 1 --directory /usr/bin
#sudo rm reden_ubuntu16_1.0.0_linux.gz

# Copy binaries to /usr/bin
sudo cp RedenMasternodeSetup/Reden-v1.0-Ubuntu16.04/reden* /usr/bin/ > /dev/null

sudo chmod 755 -R ~/RedenMasternodeSetup
sudo chmod 755 /usr/bin/reden*

#Stop daemon if it's already running
if pgrep -x 'redend' > /dev/null; then
	reden-cli stop
	echo 'sleep for 10 seconds...'
	sleep 10
fi

#Create reden.conf
if [ ! -f ~/.redencore/reden.conf ]; then 
	sudo mkdir ~/.redencore
fi

echo 'Creating reden.conf...'
cat <<EOF > ~/.redencore/reden.conf
rpcuser=redenrpc
rpcpassword=$rpcpassword
EOF

sudo chmod 755 -R ~/.redencore/reden.conf

#Starting daemon first time
redend -daemon
echo 'sleep for 10 seconds...'
sleep 10

#Generate masternode private key
echo 'Generating masternode key...'
genkey=$(reden-cli masternode genkey)
reden-cli stop

cat <<EOF > ~/.redencore/reden.conf
rpcuser=redenrpc
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
maxconnections=256
externalip=$publicip
masternode=1
masternodeprivkey=$genkey
EOF

#Starting daemon second time
redend

#Setting auto star cron job for redend
echo 'Configuring crontab job...'
cronjob='@reboot sleep 30 && redend'
crontab -l > tempcron
if ! grep -q "$cronjob" tempcron; then
	echo $cronjob >> tempcron
	crontab tempcron
fi
rm tempcron

echo -e "========================================================================
Masternode setup is complete!
========================================================================

Masternode was installed with VPS IP Address: $publicip

Masternode Private Key: $genkey

Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your Reden collateral funds):
======================================================================== \a"
echo "mn1 $publicip:$Port $genkey TxId TxIdx"
echo "========================================================================

Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your masternodes.conf file and replace:
    'mn1' - with your desired masternode name (alias)
    'TxId' - with Transaction Id from masternode outputs
    'TxIdx' - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!

To introduce your new masternode to the Reden network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a comlete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    'Node just started, not yet activated' or
    'Node  is not in masternode list', which is normal and expected.

2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: masternode start-alias mn1
    where 'mn1' is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> start alias

Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!

Currently your masternode is syncing with the Reden network...

The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
...scroll up to see previous screens...


Here are some useful commands and tools for masternode troubleshooting:

========================================================================
To view masternode configuration produced by this script in reden.conf:

cat ~/.redencore/reden.conf

Here is your reden.conf generated by this script:
---------------------------------------"
cat ~/.redencore/reden.conf
echo -e "---------------------------------------

NOTE: To edit reden.conf, first stop the redend daemon,
then edit the reden.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the redend daemon back up:

to stop:   eden-cli stop
to edit:   nano ~/.redencore/reden.conf
to start:  edend
========================================================================
To view Redend debug log showing all MN network activity in realtime:

tail -f ~/.redencore/debug.log
========================================================================
To monitor system resource utilization and running processes:

htop
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:

bash ~/RedenMasternodeSetup/nodemon.sh
========================================================================


Enjoy your Reden Masternode and thanks for using this setup script!

If you found it helpful, please donate REDEN to:
RCdYg5yq3YfymwrZi8EMBSFHxcwR7acniS

...and make sure to check back for updates!

"

~/RedenMasternodeSetup/nodemon.sh
