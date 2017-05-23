#!/bin/bash
#
# ADOBE FLASH PLAYER SILENT INSTALLER
# github.com/geoffrepoli
# v2.0.0
#################
# Finds latest version of Adobe Flash Player, downloads and install silently. 
# Cleans up install files before exiting.

APPLICATION_NAME="Adobe Flash Player"
APPLICATION_VERSION=$(/usr/bin/curl -s "http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml" | awk -F\" '/update version/{gsub(",",".");print $2}')
APPLICATION_URL="https://fpdownload.adobe.com/get/flashplayer/pdc/${APPLICATION_VERSION}/install_flash_player_osx.dmg"
SCRIPT_UUID=$(/usr/bin/uuidgen)
DMG_PATH="/private/tmp/${SCRIPT_UUID}_${APPLICATION_NAME//\ /_}.dmg"

echo "Downloading $APPLICATION_NAME v$APPLICATION_VERSION..."
/usr/bin/curl -s "$APPLICATION_URL" -o "$DMG_PATH"

echo "Installing $APPLICATION_NAME..."

# Create a temp dir to mount disk image at
TMP_MOUNT=$(/usr/bin/mktemp -d /private/tmp/${SCRIPT_UUID}_${APPLICATION_NAME//\ /_}_MOUNT.XXXX)

# Mount disk image silently
/usr/bin/hdiutil attach "$DMG_PATH" -mountpoint "$TMP_MOUNT" -nobrowse -noverify -noautoopen 1> /dev/null

# Get path to installer pkg within mounted disk image
APPLICATION_PKG=$(find "$TMP_MOUNT" -type f -name "*Flash*.pkg")

# install silently, redirect stderr to /dev/null to avoid jamf bug that reports the policy as failed
# when it see the word "error" in the output, even if the error message is unrelated/minor
/usr/sbin/installer -dumplog -pkg "$APPLICATION_PKG" -target / 2> /dev/null

# Unmount disk image, delete tempdir and dmg
echo "Cleaning up up temporary files..."
/usr/bin/hdiutil detach "$TMP_MOUNT" 1> /dev/null
rm -rf /private/tmp/"$SCRIPT_UUID"*

echo "Done"
exit 0
