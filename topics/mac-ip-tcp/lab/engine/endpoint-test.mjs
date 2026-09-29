import assert from 'node:assert/strict';
import net from 'node:net';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const endpoint = fileURLToPath(new URL('./endpoint.mjs', import.meta.url));
const node = process.execPath;

async function unusedPort() {
  const server = net.createServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const { port } = server.address();
  server.close();
  await once(server, 'close');
  return port;
}

function runEndpoint(args, env = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(node, [endpoint, ...args], {
      env: { ...process.env, ...env },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stdout = '';
    let stderr = '';
    const watchdog = setTimeout(() => {
      child.kill('SIGKILL');
      reject(new Error(`endpoint hung: ${args.join(' ')}\n${stdout}\n${stderr}`));
    }, 4000);
    child.stdout.on('data', chunk => { stdout += chunk; });
    child.stderr.on('data', chunk => { stderr += chunk; });
    child.on('error', reject);
    child.on('exit', (code, signal) => {
      clearTimeout(watchdog);
      resolve({ code, signal, stdout, stderr });
    });
  });
}

async function startEndpointServer(mode) {
  const port = await unusedPort();
  const child = spawn(node, [endpoint, 'server', '127.0.0.1', String(port), mode], {
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  let stdout = '';
  let stderr = '';
  child.stdout.on('data', chunk => { stdout += chunk; });
  child.stderr.on('data', chunk => { stderr += chunk; });

  await new Promise((resolve, reject) => {
    const deadline = setTimeout(() => reject(new Error(`server did not listen\n${stdout}\n${stderr}`)), 2000);
    const check = () => {
      if (stdout.includes('LISTEN ')) {
        clearTimeout(deadline);
        resolve();
      }
    };
    child.stdout.on('data', check);
    child.once('exit', code => {
      clearTimeout(deadline);
      reject(new Error(`server exited early (${code})\n${stdout}\n${stderr}`));
    });
    check();
  });

  return {
    port,
    output: () => ({ stdout, stderr }),
    async stop() {
      if (child.exitCode === null) child.kill('SIGTERM');
      if (child.exitCode === null) await once(child, 'exit');
    },
  };
}

test('echo server preserves the backward-compatible default payload', async t => {
  const server = await startEndpointServer('echo');
  t.after(() => server.stop());
  const result = await runEndpoint(['client', '127.0.0.1', String(server.port)]);
  assert.equal(result.code, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /ECHO "hello from A\\n"/);
  assert.match(result.stdout, /SUCCESS/);
});

test('hold server triggers the configurable read timeout', async t => {
  const server = await startEndpointServer('hold');
  t.after(() => server.stop());
  const result = await runEndpoint(
    ['client', '127.0.0.1', String(server.port), 'wait for reply'],
    { LAB_TIMEOUT_MS: '120' },
  );
  assert.equal(result.code, 1, result.stdout + result.stderr);
  assert.match(result.stdout, /CONNECTED/);
  assert.match(result.stdout, /READ_TIMEOUT \(application deadline: 120 ms\)/);
});

test('reset server exposes an after-connect reset error', async t => {
  const server = await startEndpointServer('reset');
  t.after(() => server.stop());
  const result = await runEndpoint(
    ['client', '127.0.0.1', String(server.port), 'reset me'],
    { LAB_TIMEOUT_MS: '500' },
  );
  assert.equal(result.code, 1, result.stdout + result.stderr);
  assert.match(result.stdout, /CONNECTED/);
  assert.match(result.stdout, /(AFTER_CONNECT ECONNRESET|EOF_BEFORE_COMPLETE_REPLY)/);
});

test('connection refusal is reported before the handshake completes', async () => {
  const port = await unusedPort();
  const result = await runEndpoint(
    ['client', '127.0.0.1', String(port), 'nobody home'],
    { LAB_TIMEOUT_MS: '500' },
  );
  assert.equal(result.code, 1, result.stdout + result.stderr);
  assert.match(result.stdout, /CONNECT_ERROR ECONNREFUSED/);
});

test('client reassembles a fragmented echo and supports a custom payload', async t => {
  const payload = 'fragmented echo payload';
  const server = net.createServer(socket => {
    socket.once('data', data => {
      const split = Math.max(1, Math.floor(data.length / 2));
      socket.write(data.subarray(0, split));
      setTimeout(() => socket.end(data.subarray(split)), 20);
    });
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  t.after(() => new Promise(resolve => server.close(resolve)));

  const { port } = server.address();
  const result = await runEndpoint(
    ['client', '127.0.0.1', String(port), payload],
    { LAB_TIMEOUT_MS: '500' },
  );
  assert.equal(result.code, 0, result.stdout + result.stderr);
  assert.match(result.stdout, /ECHO "fragmented echo payload"/);
  assert.match(result.stdout, /SUCCESS/);
});
