import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const godot = path.join(root, '.tools/godot/Godot_v4.7.2-stable_win64_console.exe');
const server = path.join(root, '.tools/mcp/node_modules/@coding-solo/godot-mcp/build/index.js');
for (const file of [godot, server]) {
  if (!fs.existsSync(file)) throw new Error(`Missing installation: ${file}`);
}
const child = spawn(process.execPath, [server], {
  cwd: root,
  env: { ...process.env, GODOT_PATH: godot },
  windowsHide: true,
  stdio: ['pipe', 'pipe', 'pipe'],
});
const pending = new Map();
let serial = 0;
let buffer = '';
let diagnostic = '';
child.stderr.on('data', data => { diagnostic += data.toString(); });
child.stdout.on('data', data => {
  buffer += data.toString();
  let split;
  while ((split = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, split).trim();
    buffer = buffer.slice(split + 1);
    if (!line) continue;
    try {
      const message = JSON.parse(line);
      const waiter = pending.get(message.id);
      if (waiter) {
        pending.delete(message.id);
        clearTimeout(waiter.timer);
        message.error ? waiter.reject(new Error(JSON.stringify(message.error))) : waiter.resolve(message.result);
      }
    } catch (error) { diagnostic += `\nInvalid response: ${error.message}`; }
  }
});
child.on('error', error => {
  for (const waiter of pending.values()) { clearTimeout(waiter.timer); waiter.reject(error); }
  pending.clear();
});
child.on('exit', code => {
  for (const waiter of pending.values()) {
    clearTimeout(waiter.timer);
    waiter.reject(new Error(`Server exited (${code}): ${diagnostic}`));
  }
  pending.clear();
});
function request(method, params) {
  return new Promise((resolve, reject) => {
    const id = ++serial;
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`Timed out: ${method}; ${diagnostic}`));
    }, 30000);
    pending.set(id, { resolve, reject, timer });
    child.stdin.write(JSON.stringify({ jsonrpc: '2.0', id, method, params }) + '\n');
  });
}
try {
  const handshake = await request('initialize', {
    protocolVersion: '2024-11-05', capabilities: {},
    clientInfo: { name: 'archer-environment-check', version: '1.0.0' },
  });
  child.stdin.write(JSON.stringify({ jsonrpc: '2.0', method: 'notifications/initialized' }) + '\n');
  const list = await request('tools/list', {});
  if (!list.tools?.some(tool => tool.name === 'get_godot_version')) throw new Error('Version tool missing');
  const version = await request('tools/call', { name: 'get_godot_version', arguments: {} });
  if (version.isError || !version.content?.some(item => item.text?.startsWith('4.7.2.stable'))) {
    throw new Error(`Unexpected engine response: ${JSON.stringify(version)}`);
  }
  const result = {
    checkedAt: new Date().toISOString(),
    handshake: handshake.serverInfo,
    protocolVersion: handshake.protocolVersion,
    tools: list.tools.map(tool => tool.name),
    godotVersion: version.content,
    passed: true,
  };
  fs.writeFileSync(path.join(root, '.tools/mcp-check.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify(result, null, 2));
} finally {
  child.stdin.end();
  child.kill();
}

