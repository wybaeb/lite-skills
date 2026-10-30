#!/usr/bin/env bash
set -Eeuo pipefail

export DISPLAY=:0
PROFILE=/data/profile
mkdir -p "$PROFILE" /data/downloads
chmod 700 /data "$PROFILE" /data/downloads

# Не допускаем два Chrome с одним постоянным профилем. flock освобождается
# ядром при остановке контейнера, поэтому после аварии не остаётся ложный lock.
exec 9>/data/browser-handoff.lock
if ! flock -n 9; then
  echo "Browser profile is already in use" >&2
  exit 1
fi

cleanup() { pkill -P $$ 2>/dev/null || true; }
trap cleanup EXIT

Xvfb :0 -screen 0 "${SCREEN:-1920x1080x24}" -nolisten tcp +extension RANDR &
for _ in $(seq 1 30); do [ -S /tmp/.X11-unix/X0 ] && break; sleep 0.3; done
fluxbox -log /dev/null >/dev/null 2>&1 &
x11vnc -display :0 -forever -shared -nopw -localhost -rfbport 5900 -noxdamage -quiet >/dev/null 2>&1 &
websockify --web=/usr/share/novnc 0.0.0.0:6080 127.0.0.1:5900 >/dev/null 2>&1 &

# Chrome в оконном режиме слушает CDP на loopback контейнера. Отдельный forward
# нужен только для проброса Docker; compose всё равно привязывает его к loopback хоста.
socat TCP-LISTEN:9223,reuseaddr,fork,bind=0.0.0.0 TCP:127.0.0.1:9222 >/dev/null 2>&1 &

exec google-chrome-stable \
  --user-data-dir="$PROFILE" \
  --no-sandbox \
  --no-first-run \
  --no-default-browser-check \
  --password-store=basic \
  --disable-dev-shm-usage \
  --window-position=0,0 \
  --window-size=1920,1040 \
  --remote-debugging-port=9222 \
  --remote-allow-origins=* \
  --lang=ru-RU \
  "${START_URL:-about:blank}"
