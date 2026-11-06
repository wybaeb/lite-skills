#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/browser-handoff/SKILL.md"

grep -q '/browser' "$SKILL"
grep -q '/browser blind' "$SKILL"
grep -q '/browser continue' "$SKILL"
grep -q '/browser stop' "$SKILL"
grep -q '15 минут' "$SKILL"
grep -q 'Отдельной команды передачи управления нет' "$SKILL"
grep -q 'Никогда не проси пароль, SMS-код, код 2FA, cookie' "$SKILL"
grep -q 'Не решай CAPTCHA' "$SKILL"
grep -q 'банков, государственных сервисов и криптокошельков' "$SKILL"

if grep -RIEq '127\.0\.0\.1:9222|browser-sidecar|lease id|remote-debugging|Docker socket|Передать агенту|Отозвать управление|VNC-пароль' "$ROOT/skills/browser-handoff"; then
  echo 'internal or obsolete browser implementation detail remains in the public skill' >&2
  exit 1
fi

test ! -e "$ROOT/skills/browser-handoff/assets"
test ! -e "$ROOT/skills/browser-handoff/references"
test ! -e "$ROOT/skills/browser-handoff/scripts"
echo 'PASS: current Lite browser flow, human verification, no internal implementation details'
