#!/bin/bash
#
# REMOVE SAVED WIRELESS NETWORKS
# github.com/geoffrepoli
# ===============
# Removes SSID(s) from preferred network list & removes saved login credentials from each console user's keychain
# Note: must be run as root


# ===============
# SCRIPT CONFIGURATION
# Add SSIDs to be removed in the following array, using the same formatting as the example networks:
SSIDS=( "network1" "network2" )
# ===============

# Get list of all local accounts by returning list of all accounts with UID >= 499
# while this is the most common user setup in Mac envs, tweak this to your environment's needs if necessary
LOCALUSERS=$(/usr/bin/dscl /Local/Default list /Users uid | awk '$2>=499{print $1}')

# Get the hardware port that the Mac is currently using for Wi-Fi, as this can be different across Macs
INTERFACE=$(/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | awk -F': ' '/Device/{print $NF}')

for SSID in "${SSIDS[@]}" ; do

    # Check for each ssid and remove if found
    if /usr/sbin/networksetup -listpreferredwirelessnetworks "$INTERFACE" | grep "$SSID" &> /dev/null ; then
        /usr/sbin/networksetup -removepreferredwirelessnetwork "$INTERFACE" "$SSID" &> /dev/null && 
        echo "Removed SSID: $SSID"
    fi

    # Check each local user's login keychain for the associated 802.1X password entry and remove if found
    for LOCALUSER in "${LOCALUSERS[@]}" ; do
    
        if SSID="$SSID" su "$LOCALUSER" -c '/usr/bin/security find-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$SSID" &> /dev/null' ; then 
            SSID="$SSID" su "$LOCALUSER" -c '/usr/bin/security delete-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$SSID" &> /dev/null' &&
            echo "Removed keychain entry: $SSID - $LOCALUSER"
        fi

    done

done
