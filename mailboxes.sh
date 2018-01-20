#! /bin/bash
set -uo pipefail

display_usage() {
  echo "Usage: $0 <user@example.com> (archive|purge|stats)" >&2
}

if [ "$#" -lt 2 ]; then
  display_usage
  exit 1
fi

MAILUSER=$1
ACTION=$2
DOVEADM=$(which doveadm)
ARCHIVE_SRC='INBOX'

do_stats() {
  ARCHIVES=$($DOVEADM mailbox list -u "$MAILUSER" 'Archive*' | awk -F '/' '{print $2}' | uniq)
  echo -e "\n-- Archive folders available for this mailbox : $ARCHIVES"
}

do_archive() {
  for year in 2014 2015 2016; do
    echo -e "\n--- starting $year"
    year_next=$year
    for month in $(seq -f '%02g' 1 12) ; do
      month_next=$(printf "%02d" $(expr $month + 1))
      if [ "$month" = 12 ]; then
        month_next=01
        year_next=$(($year + 1))
      fi

      echo "$DOVEADM mailbox create -u $MAILUSER "Archive/$year/$month" -s"
      $DOVEADM mailbox create -u "$MAILUSER" "Archive/$year/$month" -s 2> /dev/null

      echo "$DOVEADM -v move -u $MAILUSER Archive/$year/$month mailbox $ARCHIVE_SRC SENTBEFORE $year_next-$month_next-01 SENTSINCE $year-$month-01"
      $DOVEADM -v move -u "$MAILUSER" Archive/"$year"/"$month" mailbox $ARCHIVE_SRC SENTBEFORE $year_next-$month_next-01 SENTSINCE "$year"-"$month"-01
    done
  done
}

do_purge() {
  ## remove mails from INBOX/autopurge after 30 days
  echo -e "-- Removing mails older than 30d in folder INBOX/autopurge"
  $DOVEADM expunge -u "$MAILUSER" mailbox 'INBOX/autopurge' not FLAGGED savedbefore 30d
}

#echo "--------- All mailboxes ---------"
#$DOVEADM mailbox list -u ${MAILUSER}
#echo "---------------------------------"

case "$ACTION" in
  "archive") do_archive;;
  "stats") do_stats;;
  "purge") do_purge;;
  *) echo -e "\nUnknown action" && exit 1;;
esac
