#!/bin/bash
#
# REMOVE SAVED WPA2 ENTERPRISE WIRELESS NETWORKS
# github.com/geoffrepoli
# v1.1.0
# ===
# Removes SSID(s) from preferred network list & removes saved login credentials from each console user's keychain
# Note: must be run as root
# ===

# SCRIPT CONFIGURATION
# Add SSIDs to be removed in the following array, using the same formatting as the example networks:
wirelessNetworks=( "wireless1" "wireless2" "wireless3" )

#################

# Get list of all local accounts by returning list of all accounts with UID >= 499
# while this is the most common user setup in Mac envs, tweak this to your environment's needs if necessary
localUsers=$(/usr/bin/dscl . list /users uid | awk '$2 >= 499 {print $1}')
#
# Get the hardware port that the Mac is currently using for Wi-Fi, as this can be different across Macs
networkService=$(/usr/sbin/networksetup -listallhardwareports | grep -A1 Wi-Fi | awk -F': ' '/Device/{print $NF}')

for ssid in ${wirelessNetworks[@]}; do
    # Check for each SSID and remove if found
    if /usr/sbin/networksetup -listpreferredwirelessnetworks "$networkService" | grep "\<${ssid}\>" &> /dev/null; then
        /usr/sbin/networksetup -removepreferredwirelessnetwork "$networkService" "$ssid" &> /dev/null && 
        echo "Removed SSID: $ssid"
    fi
    # Check each local user's login keychain for the associated 802.1X password entry and remove if found
    for user in ${localUsers[@]}; do
        if ssid="$ssid" su "$user" -c '/usr/bin/security find-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$ssid" &> /dev/null' ; then 
        	ssid="$ssid" su "$user" -c '/usr/bin/security delete-generic-password -s "com.apple.network.eap.user.item.wlan.ssid.$ssid" &> /dev/null' &&
        	echo "Removed keychain entry: $ssid - $user"
        fi
    done
done
