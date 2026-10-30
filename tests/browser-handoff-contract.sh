#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/browser-handoff/SKILL.md"
CONTRACT="$ROOT/skills/browser-handoff/references/platform-contract.md"
grep -q 'capability включена' "$SKILL"
grep -q 'browser-sidecar' "$SKILL"
grep -q 'не блокируют браузер автоматически' "$SKILL"
grep -q 'не проси пароль, cookie, 2FA' "$SKILL"
grep -q 'URL, заголовок, текст страницы' "$CONTRACT"
grep -q 'remote-debugging-pipe' "$CONTRACT"
grep -q 'Не обещай инжектированный `capability`' "$CONTRACT"
grep -q 'Один handoff действует максимум 15 минут' "$CONTRACT"
node "$ROOT/skills/browser-handoff/scripts/cdp.mjs" help >/dev/null
node --check "$ROOT/skills/browser-handoff/scripts/browser-advisory.mjs"
test ! -e "$ROOT/skills/browser-handoff/assets"
if grep -RIEq 'docker compose|--no-sandbox|password-store=basic|-nopw|EXPOSE[[:space:]]+6080|127\.0\.0\.1:6080' "$ROOT/skills/browser-handoff"; then
  echo 'legacy standalone browser fallback remains in the public skill' >&2
  exit 1
fi
echo 'PASS: platform-first handoff, explicit lease, soft advisory, no secrets or floating browser download'
