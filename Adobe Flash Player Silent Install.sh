#!/usr/bin/env bash
set -u

# ADOBE FLASH PLAYER SILENT INSTALLER
# github.com/doggles
# v2.4
# ----
# Finds latest version of Adobe Flash Player, downloads and install silently. 
# Cleans up install files before exiting.
# ----

## Constants
appName="Adobe Flash Player"
appVersion=$(curl -s "http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml" | awk -F\" '/v.*=/{gsub(/,/,".");print $2}')
appURL="https://fpdownload.adobe.com/get/flashplayer/pdc/$appVersion/install_flash_player_osx.dmg"
dmgPath="/private/tmp/${uuid}_${appName//\ /_}.dmg"

# Generate UUID to reduce risk of unintended file deletion
uuid=$(uuidgen)

# Download dmg
echo "Downloading $appName v$appVersion..."
curl -s "$appURL" -o "$dmgPath"

# Create a temp dir to mount disk image
echo "Creating mountpoint"
mountPoint=$(mktemp -d /private/tmp/${uuid}_${appName//\ /_}_MOUNT.XXXX)

# Mount disk image
echo "Mounting $appName"
hdiutil attach "$dmgPath" -mountpoint "$mountPoint" -nobrowse -noverify -noautoopen >/dev/null

# Get path to installer pkg within mounted disk image
appInstaller=$(find "$mountPoint" -type f -name "*Flash*.pkg")

# Install silently, redirect stderr to /dev/null to avoid jamf bug that reports the policy as failed
# when it see the word "error" in the output, regardless of context (e.g., an app named 'Error Reporting')
echo "Installing $appName"
installer -dumplog -pkg "$appInstaller" -target / 2>/dev/null

## Cleanup temp files
echo "Cleaning up temporary files..."
hdiutil detach "$mountPoint" >/dev/null
rm -rf /private/tmp/"${uuid:?}"*

echo "Done"
exit
