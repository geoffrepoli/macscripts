#!/bin/bash
#
# WPA2 WIFI REMOVAL TOOL
# github.com/geoffrepoli
#
# Removes SSID(s) from preferred network list & removes saved login credentials from each console user's keychain
# Note: must be run as root


# SET WIRELESS NETWORKS TO BE REMOVED
# add SSIDs to be removed in the following array, using the same formatting as the example networks:
SSIDS=( "network1" "network2" )




# Get list of all local accounts by returning list of all accounts with UID >= 499
# while this is the most common user setup in Mac envs, tweak this to your environment's needs if necessary
CUSERS=$(/usr/bin/dscl /Local/Default list /Users uid | awk '$2>=499{print $1}')


# Get the hardware port that the Mac is currently using for Wi-Fi, as this can be different across Macs
EN=$(/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | awk -F': ' '/Device/{print $NF}')


for SSID in ${SSIDS[@]} ; do

    # looks for each ssid and removes if found
    if [[ $(/usr/sbin/networksetup -listpreferredwirelessnetworks $EN | grep "$SSID") ]] ; then
        /usr/sbin/networksetup -removepreferredwirelessnetwork $EN $SSID > /dev/null 2>&1 && echo "Removed SSID: $SSID"
    fi

    for CUSER in ${CUSERS[@]} ; do
    
        # Checks each local user's login keychain for the 802.1X password entry and removes if found
        if SSID="$SSID" su "$CUSER" -c '/usr/bin/security find-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$SSID" > /dev/null 2>&1' ; then 
            SSID="$SSID" su "$CUSER" -c '/usr/bin/security delete-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$SSID" > /dev/null 2>&1' && echo "Removed keychain entry: $SSID - $CUSER"
        fi

    done

done
