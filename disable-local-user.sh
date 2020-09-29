#!/bin/bash
#
# This script disables, deletes, and/or archives users on the local system.
#

ARCHIVE_DIR='/archive'

usage() {
  # Display the usage and exit.
  echo "Usage: ${0} [-dra] USER [USERN]..." >&2
  echo 'Disable local Linux account.' >&2
  echo '  -d  Deletes accounts instead of disabling them.' >&2
  echo '  -r  Removes the home directory which is associated with given account.' >&2
  echo '  -a  Creates the home directory archive which is associated with given account.' >&2
  exit 1
}

# We need to make sure the script is being executed with root privileges.
if [[ "${UID}" -ne 0 ]]
then
   echo 'Please run with sudo or as a root user.' >&2
   exit 1
fi

# Parse the options.
while getopts dra OPTION
do
  case ${OPTION} in
    d) DELETE_USER='true' ;;
    r) REMOVE_OPTION='-r' ;;
    a) ARCHIVE='true' ;;
    ?) usage ;;
  esac
done

# Remove the options & leave the remaining arguments.
shift "$(( OPTIND - 1 ))"

# Provide help to the user if they don't type in any arguments.
if [[ "${#}" -lt 1 ]]
then
  usage
fi

# Loop through all usernames which were supplied as arguments.
for USERNAME in "${@}"
do
  echo "Processing user: ${USERNAME}"

  # We need to make sure the account UID >= 1000.
  USERID=$(id -u ${USERNAME})
  if [[ "${USERID}" -lt 1000 ]]
  then
    echo "Will not remove ${USERNAME} account with UID ${USERID}." >&2
    exit 1
  fi

  # Create an archive if the user requests it.
  if [[ "${ARCHIVE}" = 'true' ]]
  then
    # We need to make sure the ARCHIVE_DIR directory actually exists.
    if [[ ! -d "${ARCHIVE_DIR}" ]]
    then
      echo "${ARCHIVE_DIR} directory is being created."
      mkdir -p ${ARCHIVE_DIR}
      if [[ "${?}" -ne 0 ]]
      then
        echo "The archive directory ${ARCHIVE_DIR} was NOT created." >&2
        exit 1
      fi
    fi

    # Archive the user's 'home' directory and move it into ARCHIVE_DIR
    HOME_DIR="/home/${USERNAME}"
    ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
    if [[ -d "${HOME_DIR}" ]]
    then
      echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
      tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
      if [[ "${?}" -ne 0 ]]
      then
        echo "${ARCHIVE_FILE} was NOT created." >&2
        exit 1
      fi
    else
      echo "${HOME_DIR} does not exist or is not a directory." >&2
      exit 1
    fi
  fi

  if [[ "${DELETE_USER}" = 'true' ]]
  then
    # Delete the user.
    userdel ${REMOVE_OPTION} ${USERNAME}

    # Check if 'userdel' command worked. If not, tell the user their account was not deleted.
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT deleted." >&2
      exit 1
    fi
    echo "The account ${USERNAME} was deleted."
  else
    chage -E 0 ${USERNAME}

    # Check if 'chage' command worked. If not, tell the user their account was not disabled.
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT disabled." >&2
      exit 1
    fi
    echo "The account ${USERNAME} was disabled."
  fi
done

exit 0
