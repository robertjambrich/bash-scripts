#!/bin/bash
#
# This script creates a new user on the local system.
# Supply a username and optionally a comment for the account as an argument.
# A password will be automatically generated for given account.
# The username, password, and host for given account gets displayed.

# We need to make sure the script is being executed with root privileges.
if [[ "${UID}" -ne 0 ]]
then
   echo 'Please run with sudo or as a root user.'
   exit 1
fi

# Provide help to the user if they don't type in any arguments.
if [[ "${#}" -lt 1 ]]
then
  echo "Usage: ${0} USER_NAME [COMMENT]..."
  echo 'The accout on the local system needs to have the name of USER_NAME and a comments field of COMMENT.'
  exit 1
fi

# First parameter is the user name.
USER_NAME="${1}"

# The rest of the parameters are reserved for the comments for given account.
shift
COMMENT="${@}"

# Generate a password.
PASSWORD=$(date +%s%N | sha256sum | head -c48)

# Create the user with the password.
useradd -c "${COMMENT}" -m ${USER_NAME}

# Check if 'useradd' command worked. If not, tell the user their account was not created.
if [[ "${?}" -ne 0 ]]
then
  echo 'The account was NOT created.'
  exit 1
fi

# Set the password.
echo ${PASSWORD} | passwd --stdin ${USER_NAME}

# Check if 'passwd' command worked.
if [[ "${?}" -ne 0 ]]
then
  echo 'The account password was not set.'
  exit 1
fi

# Have the user change their password when logged in for the first time.
passwd -e ${USER_NAME}

# Display: username, password, host on which the user was created.
echo
echo 'Username:'
echo "${USER_NAME}"
echo
echo 'Password:'
echo "${PASSWORD}"
echo
echo 'Host:'
echo "${HOSTNAME}"
exit 0
