#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

DEBUG=0

#
# ddupd
# Another Dynamic DNS Updater. But simpler.
#
# Derived from: 
#

# Set to local configuration directory
CONFDIR=/etc
CONF="$CONFDIR/ddupd.conf"

. $CONF

IP4=$( curl -4 -s "http://v4.ipv6-test.com/api/myip.php" )

##
## Logging
##
LOGFILE="/Library/Logs/ddupd.log"
find $LOGFILE -size +64k -exec rm -f {} \;
touch $LOGFILE
##

function db() {
	STDIN=0
	if [[ $DEBUG -eq 1 || -t "$STDIN" || -p /dev/stdin ]]; then
		echo "$@"
	fi
}

function log() {
	ts="$(date +'%Y-%m-%d %H:%M:%S'): [$$]"
	if [ $# -gt 0 ]; then
		db "$@"
		echo "$ts : $@" >> $LOGFILE
	else
		while read msg
		do
			db "$msg"
			echo "$ts : $msg" >> $LOGFILE
		done
	fi
}

if [ "${#IP4}" -lt 7 ]; then
	log "WARN : Our IP was reported as '$IP4'. Not continuing."
	exit 0
fi

if [ -f /tmp/ddupd_ip4 ]; then
	PP4=$(cat /tmp/ddupd_ip4)
else
	PP4=""
fi

STDIN=0
if [[ $DEBUG -eq 1 || -t "$STDIN" || -p /dev/stdin ]]; then
	log "TEST : Run interactively."
else
	if [ "$IP4" = "$PP4" ]; then
		TIME=$(date '+%H%M%S')
		# If it's between 0500 and 0501, force a heartbeat update.
		# This assumes we're being called every minute.
		if [ $TIME -lt 50000 ] || [ $TIME -gt 50100 ]; then
			TIME=$(date '+%M')
			if [ $(expr $TIME % $LOGINTERVAL) -eq 0 ]; then
				log "BEAT : IP unchanged ($IP4)."
				exit 0
			else
				exit 0
			fi
		else
			log "BEAT : Pushing $IP4 as our current address."
		fi
	fi
fi

function update_TB() {
	local user=$1
	local pass=$2
	local tid=$3
	local ip4=$4
	local url="https://${user}:${pass}@ipv4.tunnelbroker.net/nic/update"
	TBOUT=$(curl -4 -k -s "${url}?hostname=${tid}&myip=${ip4}")
	if [[ "$TBOUT" =~ "good" ]]; then
		log "OKAY : [TB] Updated tunnel $TBTID to $IP4."
	elif [[ "$TBOUT" =~ "nochg" ]]; then
		log "WARN : [TB] Sent an update to Tunnelbroker, but IP for tunnel $TBTID was already $IP4."
	else
		log "WARN : [TB] $TBOUT"
	fi
}

function update_HE() {
	local dom=$1
	local pass=$2
	local ip4=$3
	local url="https://dyn.dns.he.net/nic/update"
	FDOUT=$(curl -4 -k -s "${url}?hostname=${dom}&password=${pass}&myip=${ip4}")
	if [[ "$FDOUT" =~ "good" ]]; then
		log "OKAY : [HE] Updated Hurricane Electric domain ${dom} to ${ip4}."
	elif [[ "$FDOUT" =~ "nochg" ]]; then
		log "WARN : [HE] Sent an update to Hurricane Electric, but IP for ${dom} was already ${ip4}."
	else
		log "WARN : [HE] $FDOUT"
	fi
}

# Set Tunnelbroker IP
if [[ $TBENABLE -eq 1 ]]; then
	update_TB $TBUSER $TBPASS $TBTID $IP4
fi

# Set Hurricane Electric
if [[ $HEENABLE1 -eq 1 ]]; then
	update_HE $HEDOMN1 $HEPASS1 $IP4
fi
if [[ $HEENABLE2 -eq 1 ]]; then
	update_HE $HEDOMN2 $HEPASS2 $IP4
fi
if [[ $HEENABLE3 -eq 1 ]]; then
	update_HE $HEDOMN3 $HEPASS3 $IP4
fi

# Set DNS-O-Matic
if [ $DMENABLE = 1 ]; then
	DMOUT=$(curl -4 -k -s "https://$DMUSER:$DMPASS@updates.dnsomatic.com/nic/update?myip=$IP4")
	if [[ "$DMOUT" =~ "good" ]]; then
		log "OKAY : [DM] Updated DNS-O-Matic to $IP4."
	elif [[ "$DMOUT" =~ "nochg" ]]; then
		log "WARN : [DM] Sent an update to DNS-O-Matic, but IPs were already $IP4."
	else
		log "WARN : [DM] $DMOUT"
	fi
fi

echo "$IP4" > /tmp/ddupd_ip4
exit 0
