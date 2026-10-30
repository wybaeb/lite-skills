#!/usr/bin/env node
import net from 'node:net';

const categories = Object.freeze(['bank', 'government', 'crypto', 'unknown']);
const category = process.argv[2] || 'unknown';
if (!categories.includes(category)) {
  console.error(`category must be one of: ${categories.join(', ')}`);
  process.exit(64);
}
const client = net.createConnection({ host: '127.0.0.1', port: 9223 });
let raw = '';
client.setTimeout(2000, () => client.destroy(Object.assign(new Error('advisory timeout'), { code: 'ETIMEDOUT' })));
client.setEncoding('utf8');
client.on('connect', () => client.end(JSON.stringify({ op: 'risk', category })));
client.on('data', chunk => { raw += chunk; if (raw.length > 512) client.destroy(); });
client.on('end', () => {
  try {
    const result = JSON.parse(raw);
    if (!result.ok) { console.error(`browser advisory rejected: ${String(result.message || 'runtime rejected event').slice(0, 120)}`); process.exitCode = 1; }
  } catch { console.error('browser advisory rejected: invalid runtime response'); process.exitCode = 1; }
});
client.on('error', error => { console.error(`browser advisory unavailable: ${error.code || error.message}`); process.exitCode = 1; });
