#!/usr/bin/env node
const base = 'http://127.0.0.1:9222';
const [command = 'help', arg = ''] = process.argv.slice(2);
if (command === 'help') {
  console.log('usage: cdp.mjs targets | new-tab <https-url> | title <target-id>');
  process.exit(0);
}
if (!['targets', 'new-tab', 'title'].includes(command)) throw new Error('unsupported command');
if (command === 'new-tab') {
  const url = new URL(arg);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password) throw new Error('only credential-free http(s) URLs are allowed');
}
if (command === 'title' && !/^[A-Za-z0-9_-]{1,128}$/.test(arg)) throw new Error('invalid target id');

const version = await fetch(base + '/json/version').then(async response => {
  if (!response.ok) throw new Error('browser handoff is not active');
  return response.json();
});
if (!version.webSocketDebuggerUrl) throw new Error('runtime returned no browser endpoint');

const ws = new WebSocket(version.webSocketDebuggerUrl);
let seq = 0;
const pending = new Map();
ws.addEventListener('message', event => {
  const value = JSON.parse(String(event.data));
  if (!value.id || !pending.has(value.id)) return;
  const { resolve, reject } = pending.get(value.id);
  pending.delete(value.id);
  value.error ? reject(new Error(value.error.message || 'CDP error')) : resolve(value.result || {});
});
await new Promise((resolve, reject) => {
  ws.addEventListener('open', resolve, { once: true });
  ws.addEventListener('error', () => reject(new Error('CDP connection failed')), { once: true });
});
const call = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
  const id = ++seq;
  pending.set(id, { resolve, reject });
  ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
});

try {
  if (command === 'new-tab') {
    const result = await call('Target.createTarget', { url: arg });
    console.log(result.targetId);
  } else {
    const { targetInfos = [] } = await call('Target.getTargets');
    const pages = targetInfos.filter(target => target.type === 'page').map(({ targetId, title, url }) => ({ targetId, title, url }));
    if (command === 'targets') console.log(JSON.stringify(pages, null, 2));
    else {
      const target = pages.find(page => page.targetId === arg);
      if (!target) throw new Error('target not found');
      const { sessionId } = await call('Target.attachToTarget', { targetId: arg, flatten: true });
      const result = await call('Runtime.evaluate', { expression: 'document.title', returnByValue: true }, sessionId);
      console.log(String(result.result?.value ?? ''));
    }
  }
} finally {
  ws.close();
}
