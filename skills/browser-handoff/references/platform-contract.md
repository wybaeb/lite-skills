# Pilot-контракт платформенного browser handoff

Навык не управляет Docker и не получает внутренний broker API. Текущий stage pilot даёт
агенту только три наблюдаемые поверхности:

1. команда пользователя `/browser` — мост проверяет capability и отвечает тому же пользователю персональной
   приватной HTTPS-ссылкой, где UI запускает browser и выполняет handoff/revoke/stop;
2. `http://127.0.0.1:9222/json/version` — отсутствует до handoff, доступен агенту только
   во время lease и снова закрывается при revoke/expiry.

Не обещай инжектированный `capability`, `start`, `status`, `renew` или `revoke` tool: в pilot
их нет. Агент не строит private URL сам и не видит container name, IP, Unix path, VNC password
или lease id. Один handoff действует максимум 15 минут; при необходимости человек повторяет
кнопку, а persistent profile сохраняет вход.

## Приватный UI

Мост проверяет штатную web-auth Lite и принадлежность browser текущему `authUserKey`.
HTML/noVNC assets идут через authenticated HTTP proxy. WebSocket использует одноразовый
same-session ticket, exact Origin и фиксированный upstream `/websockify`; Cookie,
Authorization, Origin и публичный URL внутрь runtime не передаются. Stage route сохраняет
реальный base path `/bridge-dev`.

VNC credential возвращается только отдельным same-SID POST с CSRF/Origin и `no-store`, живёт
в памяти noVNC-клиента и не попадает в HTML, query или логи. Reset/revoke/stop закрывают уже
открытые viewer connections.

## Runtime boundary

- Chromium работает в отдельном per-account sidecar от uid 10002. Sidecar разделяет с
  агентом только network namespace и не монтирует agent home.
- Профиль — отдельный mount `/var/lib/lite-browser`, uid 10002, gid 10003, mode 0700.
- Chromium использует `--remote-debugging-pipe`; TCP CDP появляется на loopback только при
  активном lease и исчезает при revoke.
- Xvfb/x11vnc/noVNC слушают только loopback контейнера; Docker не публикует порты.
- Browser-UID-only `control.sock`/`viewer.sock` лежат в mount mode 0700, которого нет у
  пользователя `agent`; Docker socket не монтируется.

## Advisory event

Во время активного handoff агент может запустить bundled `scripts/browser-advisory.mjs`
только с `bank`, `government`, `crypto` или `unknown`. Runtime передаёт категорию и opaque instance id.
URL, заголовок, текст страницы, account/user id, cookies, снимки и CDP payload запрещены.
Событие рекомендательное: оно не блокирует и не банит автоматически.
