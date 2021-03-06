#!/bin/bash
# nodemon 1.0 - Methuselah Masternode Monitoring 

#Processing command line params
if [ -z $1 ]; then dly=1; else dly=$1; fi   # Default refresh time is 1 sec

datadir="/$USER/.methuselah$2"   # Default datadir is /root/.methuselah
 
# Install jq if it's not present
dpkg -s jq 2>/dev/null >/dev/null || sudo apt-get -y install jq

#It is a one-liner script for now
watch -ptn $dly "echo '===========================================================================
Outbound connections to other Methuselah nodes [methuselah datadir: $datadir]
===========================================================================
Node IP             Ping    Rx/Tx     Since  Hdrs   Height  Time   Ban
Address             (ms)   (KBytes)   Block  Syncd  Blocks  (min)  Score
==========================================================================='
methuselah-cli -datadir=$datadir getpeerinfo | jq -r '.[] | select(.inbound==false) | \"\(.addr),\(.pingtime*1000|floor) ,\
\(.bytesrecv/1024|floor)/\(.bytessent/1024|floor),\(.startingheight) ,\(.synced_headers) ,\(.synced_blocks)  ,\
\((now-.conntime)/60|floor) ,\(.banscore)\"' | column -t -s ',' && 
echo '==========================================================================='
uptime
echo '==========================================================================='
echo 'Masternode Status: \n# methuselah-cli masternode debug' && methuselah-cli -datadir=$datadir masternode debug
echo '==========================================================================='
echo 'Masternode Information: \n# methuselah-cli getinfo' && methuselah-cli -datadir=$datadir getinfo
echo '==========================================================================='
echo 'Usage: nodemon.sh [refresh delay] [datadir index]'
echo 'Example: nodemon.sh 10 22 will run every 10 seconds and query redend in /$USER/.methuselah22'
echo '\n\nPress Ctrl-C to Exit...'"
