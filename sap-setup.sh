#!/bin/bash
# Methuselah Masternode Setup Script V1.1 for Ubuntu 16.04 LTS

# Clears keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

clear
echo "Updating system and installing required packages..."
sudo apt-get update -y

# Install dig if it's not present
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils

echo "Methuselah Masternode Setup Script V1.1 for Ubuntu 16.04 LTS"

publicip=''
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n $publicip ]; then
    echo "IP Address detected:" $publicip
else
    echo -e "ERROR: Public IP Address was not detected! \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
fi

#Methuselah TCP port
Port='7575'

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


#Generating Random Password for methuselahd JSON RPC
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
#sudo rm methuselah-1.0.1.0-linux.tar.gz
#wget https://github.com/methuselah-coin/methuselah/releases/download/v1.0.1.0/methuselah-1.0.1.0-linux.tar.gz
#sudo tar -xzvf methuselah-1.0.1.0-linux.tar.gz --strip-components 1 
#sudo rm methuselah-1.0.1.0-linux.tar.gz

# Copy binaries to /usr/bin
sudo cp SAPMasternodeSetup/methuselah-1.0.1.0-linux/methuselah* /usr/bin/ > /dev/null

sudo chmod 755 -R ~/SAPMasternodeSetup
sudo chmod 755 /usr/bin/methuselah*

#Stop daemon if it's already running
if pgrep -x 'methuselah' > /dev/null; then
	methuselah-cli stop
	echo 'sleep for 10 seconds...'
	sleep 10
fi

#Create methusula.conf
if [ ! -f ~/.methuselah/methuselah.conf ]; then 
	sudo mkdir ~/.methuselah
fi

echo 'Creating methuselah.conf...'
cat <<EOF > ~/.methuselah/methuselah.conf
rpcuser=rpcuser
rpcpassword=$rpcpassword
EOF

sudo chmod 755 -R ~/.methuselah/methuselah.conf

#Starting daemon first time
methuselahd -daemon
echo 'sleep for 10 seconds...'
sleep 10

#Generate masternode private key
echo 'Generating masternode key...'
genkey=$(methuselah-cli masternode genkey)
methuselah-cli stop

cat <<EOF > ~/.methuselah/methuselah.conf
rpcuser=methuselahrpc
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
methuselahd

#Setting auto star cron job for redend
echo 'Configuring crontab job...'
cronjob='@reboot sleep 30 && methuselahd'
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
for your Hot Wallet (the wallet with your Methuselah collateral funds):
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

To introduce your new masternode to the Methuselah network, you need to
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

Currently your masternode is syncing with the methuselah network...

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

cat ~/.methuselah/methuselah.conf

Here is your methuselah.conf generated by this script:
---------------------------------------"
cat ~/.methuselah/methuselah.conf
echo -e "---------------------------------------

NOTE: To edit methuselah.conf, first stop the methuselahd daemon,
then edit the methuselah.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the methuselahd daemon back up:

to stop:   methuselah-cli stop
to edit:   nano ~/.methuselah/methuselah.conf
to start:  methuselahd
========================================================================
To view methuselahd debug log showing all MN network activity in realtime:

tail -f ~/.methuselah/debug.log
========================================================================
To monitor system resource utilization and running processes:

htop
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:

bash ~/SAPMasternodeSetup/nodemon.sh
========================================================================


Enjoy your Methuslah Masternode and thanks for using this setup script!

Authors:  AllroadAllroad [FasterPool.com], -Dwigt-

...and make sure to check back for updates!

"

~/SAPMasternodeSetup/nodemon.sh
