#!/bin/bash

#
# ddupd
# Another Dynamic DNS Updater. But simpler.
#
# Derived from: 
#

# Set to local configuration directory
CONFDIR=.
CONF="$CONFDIR/ddupd.conf"

. $CONF

IP4=`curl -4 -s "http://v4.ipv6-test.com/api/myip.php"`

##
## Logging
DDUPDLOG="/Library/Logs/ddupd.log"
find $DDUPDLOG -size +64k -exec rm -f {} \;
touch $DDUPDLOG
##

STDIN=0

if [[ -t "$STDIN" || -p /dev/stdin ]]
then
  echo interactive
else
  echo non-interactive
fi

if [ "${#IP4}" -lt 7 ]; then
	echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : Our IP was reported as '$IP4'. Not continuing." >> $DDUPDLOG
	exit 0
fi

if [ -f /tmp/ddupd_ip4 ]; then
	PP4=`cat /tmp/ddupd_ip4`
else
	PP4=""
fi

if [ "$IP4" = "$PP4" ]; then
	TIME=`date '+%H%M%S'`
	# If it's between 0500 and 0501, force a heartbeat update.
	# This assumes we're being called every minute.
	if [ $TIME -lt 50000 ] || [ $TIME -gt 50100 ]; then
		TIME=`date '+%M'`
		if [ `expr $TIME % $LOGINTERVAL` -eq 0 ]; then
			echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : BEAT : IP unchanged ($IP4)." >> $DDUPDLOG
			exit 0
		else
			exit 0
		fi
	else
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : BEAT : Pushing $IP4 as our current address." >> $DDUPDLOG
	fi
fi

# Set Tunnelbroker IP
if [ $TBENABLE = 1 ]; then
	TBOUT=`curl -4 -k -s "https://$TBUSER:$TBPASS@ipv4.tunnelbroker.net/nic/update?hostname=$TBTID&myip=$IP4"`
	if [[ "$TBOUT" =~ "good" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : OKAY : [TB] Updated tunnel $TBTID to $IP4." >> $DDUPDLOG
	elif [[ "$TBOUT" =~ "nochg" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [TB] Sent an update to Tunnelbroker, but IP for tunnel $TBTID was already $IP4." >> $DDUPDLOG
	else
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [TB] $TBOUT" >> $DDUPDLOG
	fi
fi

# Set Hurricane Electric
if [ $HEENABLE1 = 1 ]; then
	FDOUT=`curl -4 -k -s "https://dyn.dns.he.net/nic/update?hostname=$HEDOMN1&password=$HEPASS1&myip=$IP4"`
	if [[ "$FDOUT" =~ "good" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : OKAY : [HE] Updated Hurricane Electric domain $HEDOMN1 to $IP4." >> $DDUPDLOG
	elif [[ "$FDOUT" =~ "nochg" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [HE] Sent an update to Hurricane Electric, but IP for $HEDOMN1 was already $IP4." >> $DDUPDLOG
	else
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [HE] $FDOUT" >> $DDUPDLOG
	fi
fi
if [ $HEENABLE2 = 1 ]; then
  FDOUT=`curl -4 -k -s "https://dyn.dns.he.net/nic/update?hostname=$HEDOMN2&password=$HEPASS2&myip=$IP4"`
  if [[ "$FDOUT" =~ "good" ]]; then
    echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : OKAY : [HE] Updated Hurricane Electric domain $HEDOMN2 to $IP4." >> $DDUPDLOG
  elif [[ "$FDOUT" =~ "nochg" ]]; then
    echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [HE] Sent an update to Hurricane Electric, but IP for $HEDOMN2 was already $IP4." >> $DDUPDLOG
  else
    echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [HE] $FDOUT" >> $DDUPDLOG
  fi
fi
if [ $HEENABLE3 = 1 ]; then
  FDOUT=`curl -4 -k -s "https://dyn.dns.he.net/nic/update?hostname=$HEDOMN3&password=$HEPASS3&myip=$IP4"`
  if [[ "$FDOUT" =~ "good" ]]; then
    echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : OKAY : [HE] Updated Hurricane Electric domain $HEDOMN3 to $IP4." >> $DDUPDLOG
  elif [[ "$FDOUT" =~ "nochg" ]]; then
    echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [HE] Sent an update to Hurricane Electric, but IP for $HEDOMN3 was already $IP4." >> $DDUPDLOG
  else
    echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [HE] $FDOUT" >> $DDUPDLOG
  fi
fi

# Set DNS-O-Matic
if [ $DMENABLE = 1 ]; then
	DMOUT=`curl -4 -k -s "https://$DMUSER:$DMPASS@updates.dnsomatic.com/nic/update?myip=$IP4"`
	if [[ "$DMOUT" =~ "good" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : OKAY : [DM] Updated DNS-O-Matic to $IP4." >> $DDUPDLOG
	elif [[ "$DMOUT" =~ "nochg" ]]; then
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [DM] Sent an update to DNS-O-Matic, but IPs were already $IP4." >> $DDUPDLOG
	else
		echo "`date  +'%Y-%m-%d %H:%M:%S'`: [$$] : WARN : [DM] $DMOUT" >> $DDUPDLOG
	fi
fi

echo "$IP4" > /tmp/ddupd_ip4
exit 0
