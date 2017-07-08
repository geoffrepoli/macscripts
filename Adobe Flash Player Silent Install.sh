#!/usr/bin/env bash
#
# ADOBE FLASH PLAYER SILENT INSTALLER
# github.com/geoffrepoli
# v2.3
#################
# Finds latest version of Adobe Flash Player, downloads and install silently. 
# Cleans up install files before exiting.

## STATIC VARIABLES
appName="Adobe Flash Player"
appVersion=$(curl -s "http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml" | awk -F\" '/v.*=/{gsub(/,/,".");print $2}')
appURL="https://fpdownload.adobe.com/get/flashplayer/pdc/$appVersion/install_flash_player_osx.dmg"
uuid=$(uuidgen)
dmgPath="/private/tmp/${uuid}_${appName//\ /_}.dmg"

## DOWNLOAD
echo "Downloading $appName v$appVersion..."
curl -s "$appURL" -o "$dmgPath"

## INSTALLATION
echo "Installing $appName..."

# Create a temp dir to mount disk image at
mountPoint=$(mktemp -d /private/tmp/${uuid}_${appName//\ /_}_MOUNT.XXXX)

# Mount disk image silently
hdiutil attach "$dmgPath" -mountpoint "$mountPoint" -nobrowse -noverify -noautoopen >/dev/null

# Get path to installer pkg within mounted disk image
appInstaller=$(find "$mountPoint" -type f -name "*Flash*.pkg")

# install silently, redirect stderr to /dev/null to avoid jamf bug that reports the policy as failed
# when it see the word "error" in the output, even if the error message is unrelated/minor
installer -dumplog -pkg "$appInstaller" -target / 2>/dev/null

## CLEANUP
echo "Cleaning up temporary files..."

# Unmount disk image, delete tempdir and dmg
hdiutil detach "$mountPoint" >/dev/null
rm -rf /private/tmp/"$uuid"*

echo Done
