#!/usr/bin/env bash
#
# MAC UPTIME
# github.com/geoffrepoli
#
# Replacement for `uptime` command:
# 1. `uptime` command in macOS seems to be broken in 10.12.x, often incorrect total uptime
# 2. `uptime` stdout was not written with text extraction in mind
# This script uses the `kern.boottime` oid to pull the unix timestamp created at boot.
# To get seconds since boot, this number is subtracted by current unix time, then converted into a readable format

convertSeconds()
{
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  [ $D -gt 0 ] && printf '%dd ' $D
  [ $H -gt 0 ] && printf '%dh ' $H
  [ $M -gt 0 ] && printf '%dm ' $M
  [ $D -gt 0 ] || [ $H -gt 0 ] || [ $M -gt 0 ] && printf '%ds\n' $S
}

# get system boot timestamp
boot=$(sysctl -n kern.boottime | awk '{print $4-0}')

# get current epoch time
epoch=$(date +%s)

# get difference of boot and epoch and convert to days/hrs/mins/secs
convertSeconds $(( epoch - boot ))
