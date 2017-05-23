#!/bin/bash
#
# AD-TO-OD MOBILE ACCOUNT MIGRATION
# github.com/geoffrepoli
# v0.0.3
##################
# Cleanly migrates cached mobile accounts from Active Directory to another 
# directory service. Eliminates issues associated with mismatched UIDs with
# existing shortnames.

### WARNING ###
# This is a work in progress and has not yet been tested in any environment.
# Use at your own risk!
###############

LAUNCH_DAEMON="com.dsmigrate.postinstall.plist"
SCRIPT_PATH="/usr/local/dsmigrate/ds_postinstall.sh"

dirAuthName=""
dirAuthPass=""
uidNumber="1000"

_validateData() {
	__validateAuthUserInput "$dirAuthName" "$dirAuthPass"
	__validateUIDInput "$uidNumber"
}

__validateAuthUserInput() {
	if [[ -z $1 || -z $2 ]] ; then
		dirAuthName="none"
		dirAuthPass="none"
	fi
}

__validateUIDInput() {
	case $1 in
    ''|*[!0-9]*) echo "Error: UID value must be a number" ; exit 99 ;;
    *) echo "Using UID value: $uidNumber" ;;
	esac
}

_removeDirectoryServices() {
	__unbindActiveDirectory
	__removeMobileAccountPlists
	__purgeSqlindexCache
	shutdown -r now
}

__unbindActiveDirectory() { 
	searchPath=$(/usr/bin/dscl /Search read . CSPSearchPath | awk '/Active Directory/{print substr($0,2)}')
	/usr/sbin/dsconfigad -remove -force -u "$dirAuthName" -p "$dirAuthPass"
	/usr/bin/dscl /Search/Contacts delete . CSPSearchPath "$searchPath"
	/usr/bin/dscl /Search delete . CSPSearchPath "$searchPath"
	/usr/bin/dscl /Search change . SearchPolicy dsAttrTypeStandard:CSPSearchPath dsAttrTypeStandard:NSPSearchPath
	/usr/bin/dscl /Search/Contacts change . SearchPolicy dsAttrTypeStandard:CSPSearchPath dsAttrTypeStandard:NSPSearchPath
}

__removeMobileAccountPlists() {
	mobileAccounts=$(/usr/bin/dscl . list /users uid | awk -v num="$uidNumber" '$2>=num{print $1}')
	while IFS= read -r account ; do
  	rm -f var/db/dslocal/nodes/Default/users/"$account".plist
	done <<< "$mobileAccounts"
}

__purgeSqlindexCache() {
	rm -f /var/db/dslocal/nodes/Default/sqlindex
	rm -f /var/db/dslocal/nodes/Default/sqlindex-shm
	rm -f /var/db/dslocal/nodes/Default/sqlindex-wal
}

_configureRestartTasks() {
	__createLaunchDaemon
	__createLaunchScript
}

__createLaunchDaemon() {
	cat <<-EOT > /Library/LaunchDaemons/"$LAUNCH_DAEMON"
	<?xml version="1.0" encoding="UTF-8"?> 
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
	<plist version="1.0"> 
	<dict>
    	<key>Label</key> 
    	<string>${LAUNCH_DAEMON%.*}</string> 
    	<key>ProgramArguments</key> 
    	<array>
        	<string>/bin/bash</string>
        	<string>-c</string>
        	<string>${SCRIPT_PATH}</string>
    	</array>
    	<key>RunAtLoad</key>
    	<true/>
	</dict> 
	</plist>
	EOT
	chown root:wheel /Library/LaunchDaemons/"$LAUNCH_DAEMON"
	chmod 644 /Library/LaunchDaemons/"$LAUNCH_DAEMON"
}

__createLaunchScript() {
	mkdir ${SCRIPT_PATH%/*}
	cat <<-EOT > "$SCRIPT_PATH"
	#!/bin/bash
	sleep 2
	## DIRECTORY BINDING SCRIPT SHOULD GO HERE
	## OR A JAMF POLICY -TRIGGER BIND COMMAND
	for userHome in /Users/* ; do
		if [[ ${userHome##*/} != Shared && ${userHome##*/} != Guest ]] ; then
			userUID=$(/usr/bin/dscl . read /users/${userHome##*/} UniqueID | awk -F': ' '{print $NF}')
			chown -R "$userUID" "$userHome"
		fi
	done
	rm -f /Library/LaunchDaemons/${LAUNCH_DAEMON}
	rm -fdr ${SCRIPT_PATH%/*}
	exit 0
	EOT
	chown root:admin "$SCRIPT_PATH"
	chmod 755 "$SCRIPT_PATH"
}

_validateData
_configureRestartTasks
_removeDirectoryServices
