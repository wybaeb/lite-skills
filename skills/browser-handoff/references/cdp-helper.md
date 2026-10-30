# Минимальный CDP helper после handoff

Helper лежит в `scripts/cdp.mjs` этого навыка и использует только встроенные Node.js
`fetch` и `WebSocket`. Сначала проверь handoff:

```bash
curl --fail --silent http://127.0.0.1:9222/json/version >/dev/null
```

Примеры безопасного чтения и открытия отдельной вкладки:

```bash
node scripts/cdp.mjs targets
node scripts/cdp.mjs new-tab https://example.com/
node scripts/cdp.mjs title <target-id>
```

`new-tab` принимает только обычный `http(s)` URL без username/password. Helper не имеет
команд для cookies, storage state, password fields, скачивания профиля или обхода CAPTCHA.
Он не держит lease: revoke/expiry закроет соединение. Финальное внешнее действие всё равно
требует отдельного явного подтверждения пользователя.
