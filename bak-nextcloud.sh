#!/bin/bash
#
# Backup NextCloud before upgrade

set -euo pipefail
IFS=$'\n\t'

# uncomment for debugging
#set -x

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

info() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&1
}

if [ "$EUID" -ne 0 ]
  then err "Please run as root"
  exit
fi

readonly NOW=$(date +"%Y%m%d")
readonly ROOTDIR='/root/'

NC_PATH=$(find /var/www -iname '*nextcloud*' | head -n 1)

read -p "Is ${NC_PATH} your NextCloud dir: " VAR_INPUT

# Sanitize input and assign to new variable
VAR_CLEAN="`echo "${VAR_INPUT}" | tr -cd '[:alnum:] [:space:]'`"
if [[ "$VAR_CLEAN" != "" ]] ; then
  NC_PATH=${VAR_CLEAN}
fi

echo -e "Let's start with mysql backup (please type your DB password)"
mysqldump --lock-tables -h 127.0.0.1 -u nextclouduser -p nextcloud > ${ROOTDIR}nextcloud-sqlbkp_${NOW}.bak

info "Creating archive for ${NC_PATH} dir."
tar cfz ${ROOTDIR}nextcloud-config_${NOW}.tgz ${NC_PATH}

info "All tasks done. Files stored in ${ROOTDIR}"
