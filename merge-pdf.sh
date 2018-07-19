#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

REAL_USER=$(who -m | cut -d " " -f 1)
KID_NAME="toto"
NC_DIR="/data/nextcloud-data/$REAL_USER/files/Documents/$KID_NAME/CRECHE/"

echo ""
files=$(find $NC_DIR -type f -mmin -60)

echo "[x] Fichiers trouvés :"
for file in $files ; do
  short=$(echo $file | cut -d "/" -f 8-9)
  echo -e "    $short"
done

pdftk ${files[@]} cat output output.pdf
echo "[x] Fichiers PDF fusionnés"
echo -e "\n======================================================="
echo "Actions à effectuer"
echo "[ ] $ mv output.pdf 2018_JUIN_fusion_creche_$KID_NAME.pdf"
echo "[ ] $ cp 2018_JUIN_fusion_creche_$KID_NAME.pdf ~/openbar/."
