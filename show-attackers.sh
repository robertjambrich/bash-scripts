#!/bin/bash

# This script counts the number of failed logins by IP address.
# If there are any IPs with amount of failures exceeding LIMIT, it displays: count, IP, location.

LIMIT='10'
LOG_FILE="${1}"

# We need to make sure that file was supplied as an argument.
if [[ ! -e "${LOG_FILE}" ]]
then 
  echo "Cannot open file: ${LOG_FILE}" >&2
  exit 1
fi

# Display CSV header.
echo 'Count,IP,Location'

# Loop through the list of failed attempts and corresponding IP addresses.
grep Failed ${LOG_FILE} | awk '{print $(NF - 3)}' | sort | uniq -c | sort -nr |  while read COUNT IP
do
  # If the number of failed attempts > limit, display count, IP, location.
  if [[ "${COUNT}" -gt "${LIMIT}" ]]
  then
    LOCATION=$(geoiplookup ${IP} | awk -F ', ' '{print $2}')
    echo "${COUNT},${IP},${LOCATION}"
  fi
done
exit 0
