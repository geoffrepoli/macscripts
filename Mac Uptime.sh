#!/usr/bin/env bash
#
# MAC UPTIME
# github.com/doggles
#
# Replacement for `uptime` command:
# 1. `uptime` command in macOS seems to be broken in 10.12.x, often incorrect total uptime
# 2. `uptime` stdout was not written with text extraction in mind
# This script uses the `kern.boottime` oid to pull the unix timestamp created at boot.
# To get seconds since boot, this number is subtracted by current unix time, then converted into a readable format

convertSeconds()
{
  local day=$(($1/60/60/24))
  local hrs=$(($1/60/60%24))
  local min=$(($1/60%60))
  local sec=$(($1%60))
  [ $day -gt 0 ] && printf '%dd ' $day
  [ $hrs -gt 0 ] && printf '%dh ' $hrs
  [ $min -gt 0 ] && printf '%dm ' $min
  [ $day -gt 0 ] || [ $hrs -gt 0 ] || [ $min -gt 0 ] && printf '%ds\n' $sec
}

# get system boot timestamp
boot=$(sysctl -n kern.boottime | awk '{print $4-0}')

# get current epoch time
epoch=$(date +%s)

# get difference of boot and epoch and convert to days/hrs/mins/secs
uptime=$(convertSeconds $(( epoch - boot )))

# echo result as jamf pro extension attribute
echo "<result>$uptime</result>"
