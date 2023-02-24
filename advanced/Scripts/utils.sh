#!/usr/bin/env sh
# shellcheck disable=SC3043 #https://github.com/koalaman/shellcheck/wiki/SC3043#exceptions

# Pi-hole: A black hole for Internet advertisements
# (c) 2017 Pi-hole, LLC (https://pi-hole.net)
# Network-wide ad blocking via your own hardware.
#
# Script to hold utility functions for use in other scripts
#
# This file is copyright under the latest version of the EUPL.
# Please see LICENSE file for your rights under this license.

# Basic Housekeeping rules
#  - Functions must be self contained
#  - Functions should be grouped with other similar functions
#  - Functions must be documented
#  - New functions must have a test added for them in test/test_any_utils.py

#######################
# Takes Three arguments: file, key, and value.
#
# Checks the target file for the existence of the key
#   - If it exists, it changes the value
#   - If it does not exist, it adds the value
#
# Example usage:
# addOrEditKeyValPair "/etc/pihole/setupVars.conf" "BLOCKING_ENABLED" "true"
# TODO: We miight not actually need this function in v6
#######################
addOrEditKeyValPair() {
  local file="${1}"
  local key="${2}"
  local value="${3}"

  # touch file to prevent grep error if file does not exist yet
  touch "${file}"

  if grep -q "^${key}=" "${file}"; then
    # Key already exists in file, modify the value
    sed -i "/^${key}=/c\\${key}=${value}" "${file}"
  else
    # Key does not already exist, add it and it's value
    echo "${key}=${value}" >> "${file}"
  fi
}

#######################
# Takes two arguments: file, and key.
# Adds a key to target file
#
# Example usage:
# addKey "/etc/dnsmasq.d/01-pihole.conf" "log-queries"
#######################
addKey(){
  local file="${1}"
  local key="${2}"

  # touch file to prevent grep error if file does not exist yet
  touch "${file}"

  if ! grep -q "^${key}" "${file}"; then
    # Key does not exist, add it.
    echo "${key}" >> "${file}"
  fi
}

#######################
# Takes two arguments: file, and key.
# Deletes a key or key/value pair from target file
#
# Example usage:
# removeKey "/etc/pihole/setupVars.conf" "PIHOLE_DNS_1"
#######################
removeKey() {
  local file="${1}"
  local key="${2}"
  sed -i "/^${key}/d" "${file}"
}

#######################
# returns path of FTL's PID  file
#######################
getFTLPIDFile() {
  local FTLCONFFILE="/etc/pihole/pihole-FTL.conf"
  local DEFAULT_PID_FILE="/run/pihole-FTL.pid"
  local FTL_PID_FILE

  if [ -s "${FTLCONFFILE}" ]; then
    # if PIDFILE is not set in pihole-FTL.conf, use the default path
    FTL_PID_FILE="$({ grep '^PIDFILE=' "${FTLCONFFILE}" || echo "${DEFAULT_PID_FILE}"; } | cut -d'=' -f2-)"
  else
    # if there is no pihole-FTL.conf, use the default path
    FTL_PID_FILE="${DEFAULT_PID_FILE}"
  fi

  echo "${FTL_PID_FILE}"
}

#######################
# returns FTL's PID based on the content of the pihole-FTL.pid file
#
# Takes one argument: path to pihole-FTL.pid
# Example getFTLPID "/run/pihole-FTL.pid"
#######################
getFTLPID() {
    local FTL_PID_FILE="${1}"
    local FTL_PID

    if [ -s "${FTL_PID_FILE}" ]; then
        # -s: FILE exists and has a size greater than zero
        FTL_PID="$(cat "${FTL_PID_FILE}")"
        # Exploit prevention: unset the variable if there is malicious content
        # Verify that the value read from the file is numeric
        expr "${FTL_PID}" : "[^[:digit:]]" > /dev/null && unset FTL_PID
    fi

    # If FTL is not running, or the PID file contains malicious stuff, substitute
    # negative PID to signal this
    FTL_PID=${FTL_PID:=-1}
    echo  "${FTL_PID}"
}

#######################
# returns value from FTLs config file using pihole-FTL --config
#
# Takes one argument: key
# Example getFTLConfigValue dns.piholePTR
#######################
getFTLConfigValue(){
  pihole-FTL --config -q "${1}"
}

#######################
# sets value in FTLs config file using pihole-FTL --config
#
# Takes two arguments: key and value
# Example setFTLConfigValue dns.piholePTR PI.HOLE
#
# Note, for complex values such as dns.upstreams, you should wrap the value in single quotes:
# setFTLConfigValue dns.upstreams '[ "8.8.8.8" , "8.8.4.4" ]'
#######################
setFTLConfigValue(){
  pihole-FTL --config "${1}" "${2}" >/dev/null
}
