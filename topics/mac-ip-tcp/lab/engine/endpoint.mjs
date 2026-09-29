import net from 'node:net';

// A tiny, intentionally unframed byte echo protocol. One data event is NOT
// assumed to equal one TCP segment, write(), or application message.
const [role, host, portText, ...extra] = process.argv.slice(2);
const port = Number(portText);
const modes = new Set(['echo', 'hold', 'reset']);
const mode = extra[0] ?? 'echo';
const timeoutText = process.env.LAB_TIMEOUT_MS ?? '2000';
const timeoutMs = Number(timeoutText);

const validCommon = ['server', 'client'].includes(role) && net.isIP(host) &&
  Number.isInteger(port) && port >= 1 && port <= 65535;
const validRoleOptions = role === 'server' ? modes.has(mode) :
  Number.isInteger(timeoutMs) && timeoutMs > 0;

if (!validCommon || !validRoleOptions) {
  console.error('Usage: node endpoint.mjs server IP PORT [echo|hold|reset]');
  console.error('       node endpoint.mjs client IP PORT [PAYLOAD...]');
  console.error('       LAB_TIMEOUT_MS sets the client deadline (default: 2000).');
  process.exit(2);
}

if (role === 'server') {
  const sockets = new Set();
  const server = net.createServer(socket => {
    sockets.add(socket);
    console.log(`ACCEPT ${socket.remoteAddress}:${socket.remotePort} mode=${mode}`);
    socket.on('error', error => console.log(`SOCKET_ERROR ${error.code}`));
    socket.on('close', () => sockets.delete(socket));
    socket.on('data', chunk => {
      console.log(`RECEIVED bytes=${chunk.length}`);
      if (mode === 'echo') socket.write(chunk);
      else if (mode === 'reset') socket.resetAndDestroy();
      // hold: keep TCP open but deliberately produce no application reply.
    });
  });

  server.on('error', error => {
    console.error(`SERVER_ERROR ${error.code}: ${error.message}`);
    process.exitCode = 2;
  });
  server.listen(port, host, () => console.log(`LISTEN ${host}:${port} mode=${mode}`));

  const stop = () => {
    for (const socket of sockets) socket.destroy();
    server.close();
  };
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);
} else {
  // Preserve the original no-payload CLI behavior while allowing arbitrary text.
  const message = Buffer.from(extra.length > 0 ? extra.join(' ') : 'hello from A\n');
  const started = Date.now();
  const socket = new net.Socket();
  let connected = false;
  let finished = false;
  let received = Buffer.alloc(0);
  let timer;

  const finish = (label, exitCode = 0) => {
    if (finished) return;
    finished = true;
    clearTimeout(timer);
    console.log(`${label} elapsed_ms=${Date.now() - started}`);
    process.exitCode = exitCode;
    socket.destroy();
  };

  timer = setTimeout(
    () => finish(`CONNECT_TIMEOUT (application deadline: ${timeoutMs} ms)`, 1),
    timeoutMs,
  );
  socket.on('connect', () => {
    connected = true;
    clearTimeout(timer);
    console.log('CONNECTED');
    timer = setTimeout(
      () => finish(`READ_TIMEOUT (application deadline: ${timeoutMs} ms)`, 1),
      timeoutMs,
    );
    socket.write(message);
  });
  socket.on('data', chunk => {
    received = Buffer.concat([received, chunk]);
    if (received.length >= message.length) {
      if (received.equals(message)) {
        console.log(`ECHO ${JSON.stringify(received.toString())}`);
        finish('SUCCESS');
      } else {
        finish('UNEXPECTED_REPLY', 1);
      }
    }
  });
  socket.on('error', error => {
    finish(`${connected ? 'AFTER_CONNECT' : 'CONNECT_ERROR'} ${error.code}`, 1);
  });
  socket.on('end', () => {
    if (!finished) finish('EOF_BEFORE_COMPLETE_REPLY', 1);
  });
  socket.connect(port, host);
}
