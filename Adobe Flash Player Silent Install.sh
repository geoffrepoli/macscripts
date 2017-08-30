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
APP_NAME='Adobe Flash Player'
XML_URL='http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml'
UUID=$(uuidgen)

## Variables
app_vers=$(curl -s $XML_URL | awk -F\" '/v.*=/{gsub(/,/,".");print $2}')
app_url="https://fpdownload.adobe.com/get/flashplayer/pdc/${app_vers}/install_flash_player_osx.dmg"
dmg_path="/private/tmp/${UUID}_${APP_NAME//\ /_}.dmg"

# Download dmg
echo "Downloading $APP_NAME v$app_vers..."
curl -s "$app_url" -o "$dmg_path"

# Create a temp dir to mount disk image
echo "Creating mountpoint"
mount_point=$(mktemp -d /private/tmp/${UUID}_${APP_NAME//\ /_}.XXXX)

# Mount disk image
echo "Mounting $APP_NAME"
hdiutil attach "$dmg_path" -mountpoint "$mount_point" -nobrowse -noverify -noautoopen >/dev/null

# Get path to installer pkg within mounted disk image
app_installer=$(find "$mount_point" -type f -name "*Flash*.pkg")

# Install silently, redirect stderr to /dev/null to avoid jamf bug that reports the policy as failed
# when it see the word "error" in the output, regardless of context (e.g., an app named 'Error Reporting')
echo "Installing $APP_NAME"
installer -dumplog -pkg "$app_installer" -target / &>/dev/null

## Cleanup temp files
echo "Cleaning up temporary files..."
hdiutil detach "$mount_point" >/dev/null
rm -rf /private/tmp/${UUID:?}*

echo "Done"
exit
