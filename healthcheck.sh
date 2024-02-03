#!/bin/sh
# Check FreeSwitch status
fs_cli -x status | grep -q ^UP || exit 1