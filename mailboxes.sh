#! /bin/bash
set -uo pipefail

MAILUSER='user@example.com'
YEAR_PRE=$(expr $(date +%Y) - 1)
YEAR_CUR=$(date +%Y)
ARCHIVE_SRC='INBOX'

ARCHIVES=$(doveadm mailbox list -u ${MAILUSER} 'Archive*' | awk -F '/' '{print $2}' | uniq)

echo -e "\n-- Archive folders available for this mailbox : $ARCHIVES"

#echo "--------- All mailboxes ---------"
#doveadm mailbox list -u ${MAILUSER}
#echo "---------------------------------"

for year in 2014 2015 2016; do
  echo -e "\n--- starting $year"
  year_next=$year
  for month in $(seq -f '%02g' 1 12) ; do
    month_next=$(printf "%02d" $(expr $month + 1))
    if [ $month = 12 ]; then
      month_next=01
      year_next=$(expr $year + 1)
    fi
    echo "doveadm mailbox create -u ${MAILUSER} "Archive/$year/$month" -s"
    doveadm mailbox create -u ${MAILUSER} "Archive/$year/$month" -s 2> /dev/null

    echo "doveadm -v move -u ${MAILUSER} Archive/$year/$month mailbox $ARCHIVE_SRC SENTBEFORE $year_next-$month_next-01 SENTSINCE $year-$month-01"
    doveadm -v move -u ${MAILUSER} Archive/$year/$month mailbox $ARCHIVE_SRC SENTBEFORE $year_next-$month_next-01 SENTSINCE $year-$month-01
  done
done

## remove mails from INBOX/autopurge after 30 days
echo -e "\n-- Suppression des mails anciens du dossier INBOX/autopurge"
doveadm expunge -u ${MAILUSER} mailbox 'INBOX/autopurge' not FLAGGED savedbefore 30d
