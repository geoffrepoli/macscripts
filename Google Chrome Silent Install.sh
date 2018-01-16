#!/usr/bin/env bash
set -u

# GOOGLE CHROME LATEST VERSION SILENT INSTALLER
# github.com/geoffrepoli
# v1.1
# ----
# Finds latest version of Google Chrome, downloads and install silently. 
# Cleans up install files before exiting.
# ----

APPNAME="Google Chrome"
DMGPATH="/tmp/googlechrome.dmg"
MNTPOINT=$(mktemp -d /tmp/googlechrome.XXXX)
DOWNLOADURL="https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg"

echo "Running Script: Install $APPNAME"
echo "Downloading ${DMGPATH/\/*\/}"
curl -s --output "$DMGPATH" "$DOWNLOADURL"

echo "Mounting ${DMGPATH}"
hdiutil attach "$DMGPATH" -mountpoint "$MNTPOINT" -noverify -nobrowse -noautoopen &>/dev/null

echo "Copying $APPNAME to Applications folder"
ditto -rsrc "${MNTPOINT}/Google Chrome.app" "/Applications/Google Chrome.app"

echo "Cleaning up temp files"
hdiutil detach "$MNTPOINT" &>/dev/null
rm -rf "$MNTPOINT"
rm -rf "$DMGPATH"

echo "Successfully installed. Exiting"
exit 0
