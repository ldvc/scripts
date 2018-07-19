#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

REAL_USER=$(who -m | cut -d " " -f 1)
KIDS=(luke leia)

for kid in ${KIDS[*]}; do

  NC_DIR="/data/nextcloud-data/$REAL_USER/files/Documents/$kid/CRECHE/"
  echo ""
  files=$(find "$NC_DIR" -type f -mmin -60)

  if [ -z "$files" ] ; then
    echo "[ ] Aucun fichier trouvé pour $kid !"
    exit 10
  else
    echo "[x] Fichiers trouvés pour $kid :"
    for file in $files ; do
      short=$(echo "$file" | cut -d "/" -f 8-9)
      echo -e "    $short"
    done
  fi

  #pdftk ${files[@]} cat output output.pdf
  echo "[x] Fichiers PDF fusionnés"
  echo -e "\n======================================================="
  echo "Actions à effectuer"
  echo "[ ] $ mv output.pdf 2018_JUIN_fusion_creche_$kid.pdf"
  echo "[ ] $ cp 2018_JUIN_fusion_creche_$kid.pdf ~/openbar/."
done
