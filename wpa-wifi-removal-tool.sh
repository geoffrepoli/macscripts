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

    # Check for each ssid and remove if found
    if /usr/sbin/networksetup -listpreferredwirelessnetworks $EN | grep "$SSID" &> /dev/null ; then
        /usr/sbin/networksetup -removepreferredwirelessnetwork $EN $SSID &> /dev/null && echo "Removed SSID: $SSID"
    fi

    # Check each local user's login keychain for the associated 802.1X password entry and remove if found
    for CUSER in ${CUSERS[@]} ; do
    
        if SSID="$SSID" su "$CUSER" -c '/usr/bin/security find-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$SSID" &> /dev/null' ; then 
            SSID="$SSID" su "$CUSER" -c '/usr/bin/security delete-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$SSID" &> /dev/null' && echo "Removed keychain entry: $SSID - $CUSER"
        fi

    done

done
