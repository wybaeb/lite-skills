# Архитектура browser handoff в Lite

Этот навык поддерживает только встроенный платформенный runtime из
[`platform-contract.md`](platform-contract.md). Самостоятельного Docker Compose,
публикации noVNC/CDP, SSH-туннеля или fallback-контейнера в навыке нет.

```text
пользователь ─ HTTPS + Lite auth ─ private viewer handler ─ browser-owned viewer.sock
                                                               │
                                                        noVNC / x11vnc
                                                               │
агент ─ CDP 127.0.0.1:9222 только после handoff ─ Chromium remote-debugging-pipe
                                                               │
                                             отдельный persistent profile mount
```

Хостовый broker связывает `authUserKey` с обычным agent-контейнером, отдельным
browser-sidecar, профилем и Unix transport. Sidecar делит с агентом только network
namespace; agent home и project mounts в sidecar отсутствуют.
Клиент не передаёт имя контейнера, путь, IP, порт или target. Контейнер не получает
Docker socket и не публикует 5900/6080/9222. HTML и WebSocket проходят одну приватную
авторизацию Lite; WebSocket использует одноразовый ticket и фиксированный upstream path.

Chromium работает от отдельного uid. Password Manager, autofill платёжных карт и browser
sync отключены managed policy, а cookies и сессия сайта остаются в отдельном профиле.
До явной кнопки handoff агент не имеет CDP. Revoke и истечение lease закрывают уже
открытые automation-соединения.

Если `/browser` сообщает, что capability отсутствует, навык должен остановиться и назвать отсутствующий компонент.
Он не вправе поднимать собственный браузер, применять старые compose-шаблоны или предлагать
публичный/loopback VNC как замену платформенной ссылке.
