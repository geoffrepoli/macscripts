#!/bin/bash
#
# ADOBE FLASH PLAYER SILENT INSTALLER
# github.com/geoffrepoli

# Create UUID to safely perform `rm -f` on workstations
UUID=$(uuidgen)

# Direct download URL to flash installer dmg contains the current version number and thus changes with each new version.
# Source URL to Adobe XML file that contains element with current version #
SOURCE="http://fpdownload2.macromedia.com/get/flashplayer/update/current/xml/version_en_mac_pl.xml"

# Extract current version element from XML, format for use in direct download URL
VERSION=$(curl -s "$SOURCE" | grep -e "update version" | awk -F\" '{print $2}' | sed 's/,/./')
DOWNLOADURL="https://fpdownload.adobe.com/get/flashplayer/pdc/${VERSION}/install_flash_player_osx.dmg"
DOWNLOADPATH="/private/tmp/${UUID}_adobe_flash_${VERSION}_installer.dmg"

echo "Downloading Adobe Flash Player $VERSION Installer..."
curl -s "$DOWNLOADURL" -o "$DOWNLOADPATH"

echo "Installing Adobe Flash Player..."
# Create a temp dir to mount disk image at
TMPMOUNT=$(mktemp -d /private/tmp/"$UUID"_adobe_flash_"$VERSION"_tmpdir.XXXX)

# Mount disk image silently
hdiutil attach "$DOWNLOADPATH" -mountpoint "$TMPMOUNT" -nobrowse -noverify -noautoopen 1> /dev/null

# Get path to installer pkg within mounted disk image
INSTALLPKG=$(find "$TMPMOUNT" -type f -name "*Flash*.pkg")

# install silently, redirect stderr to /dev/null to avoid jamf bug that reports the policy as failed
# when it see the word "error" in the output, even if the error message is unrelated/minor
installer -dumplog -pkg "$INSTALLPKG" -target / 2> /dev/null

# Unmount disk image, delete tempdir and dmg
echo "Cleaning up up temporary files"
hdiutil detach "$TMPMOUNT" 1> /dev/null
rm -rf /private/tmp/"$UUID"*

echo "Done"
