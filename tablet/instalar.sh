#!/data/data/com.termux/files/usr/bin/bash
# Instalación única en Termux del puente GitHub -> Google Drive para el noticiero.
set -e
DIR="$HOME/.noticiero"; mkdir -p "$DIR"

echo "== Instalando rclone, cron y utilidades =="
pkg install -y rclone cronie termux-services curl

echo; read -rp "Repositorio de GitHub (usuario/repositorio): " REPO
read -rsp "Token de GitHub (solo lectura, no se mostrará): " TOKEN; echo
printf 'REPO=%q\nTOKEN=%q\n' "$REPO" "$TOKEN" > "$DIR/conf"; chmod 600 "$DIR/conf"

curl -fsSL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github.raw" \
  -o "$DIR/bajar_noticiero.sh" "https://api.github.com/repos/$REPO/contents/tablet/bajar_noticiero.sh?ref=main"
chmod +x "$DIR/bajar_noticiero.sh"

echo; echo "== Conectando Google Drive =="
echo "Se abrirá (o se mostrará) un enlace: ábrelo en el navegador de la tablet, entra con tu cuenta de Google y autoriza."
rclone config create noticias drive scope=drive root_folder_id=1EB-53epXEhO7yvenX5ZujYCPQp5O-u2C

echo; echo "== Programando la descarga diaria (4:50, 5:20 y 6:00) =="
( crontab -l 2>/dev/null | grep -v bajar_noticiero
  echo "50 4 * * * $DIR/bajar_noticiero.sh"
  echo "20 5 * * * $DIR/bajar_noticiero.sh"
  echo "0 6 * * * $DIR/bajar_noticiero.sh" ) | crontab -
sv-enable crond 2>/dev/null || true

echo; echo "== Prueba ahora =="
"$DIR/bajar_noticiero.sh"; tail -3 "$DIR/job.log"
echo; echo "Listo. Si 'sv-enable' falló, cierra Termux por completo, ábrelo de nuevo y ejecuta: sv-enable crond"
