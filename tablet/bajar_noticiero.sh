#!/data/data/com.termux/files/usr/bin/bash
# Descarga el noticiero del día desde GitHub y lo sube a Google Drive (01_Noticias).
# Lo ejecuta cron en Termux varias veces en la madrugada; si ya se subió, no hace nada.
set -uo pipefail
DIR="$HOME/.noticiero"
LOG="$DIR/job.log"
source "$DIR/conf"   # define TOKEN y REPO (usuario/repositorio)

API="https://api.github.com/repos/$REPO/contents"
H=(-H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github.raw")

NAME=$(curl -fsSL "${H[@]}" "$API/latest.txt?ref=audio" 2>>"$LOG" | head -1 | tr -d '\r\n ')
if [ -z "$NAME" ]; then echo "$(date '+%F %T') sin audio disponible todavía" >> "$LOG"; exit 0; fi

if grep -qx "$NAME" "$DIR/subidos.txt" 2>/dev/null; then
  echo "$(date '+%F %T') $NAME ya estaba subido" >> "$LOG"; exit 0
fi

if curl -fsSL "${H[@]}" -o "$DIR/tmp.mp3" "$API/latest.mp3?ref=audio" 2>>"$LOG" \
   && rclone copyto "$DIR/tmp.mp3" "noticias:$NAME" >> "$LOG" 2>&1; then
  echo "$NAME" >> "$DIR/subidos.txt"
  echo "$(date '+%F %T') subido $NAME" >> "$LOG"
else
  echo "$(date '+%F %T') ERROR al bajar o subir $NAME" >> "$LOG"
fi
rm -f "$DIR/tmp.mp3"
