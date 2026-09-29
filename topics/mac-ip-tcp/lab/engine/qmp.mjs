import net from 'node:net';
const [socketPath, expectedName, action = 'status'] = process.argv.slice(2);
if (!socketPath || !expectedName || !['status', 'quit'].includes(action)) process.exit(2);
const socket = net.createConnection(socketPath);
let buffer = '', step = 0, done = false;
const finish = code => { if (done) return; done = true; clearTimeout(timer); socket.destroy(); process.exitCode = code; };
const timer = setTimeout(() => { console.error('QMP timeout'); finish(3); }, 4000);
const send = (execute, id) => socket.write(JSON.stringify({ execute, id }) + '\r\n');
socket.on('error', error => { console.error(`QMP ${error.code}`); finish(['ENOENT','ECONNREFUSED'].includes(error.code) ? 1 : 3); });
socket.on('data', chunk => {
  buffer += chunk.toString();
  while (buffer.includes('\n')) {
    const end = buffer.indexOf('\n'); const line = buffer.slice(0, end).trim(); buffer = buffer.slice(end + 1);
    if (!line) continue;
    let response; try { response = JSON.parse(line); } catch { finish(3); return; }
    if (response.error) { console.error(JSON.stringify(response.error)); finish(3); return; }
    if (response.QMP && step === 0) { step = 1; send('qmp_capabilities', 1); }
    else if (response.id === 1) { step = 2; send('query-name', 2); }
    else if (response.id === 2) {
      if (response.return?.name !== expectedName) { console.error('QMP ownership mismatch'); finish(3); return; }
      step = 3; send(action === 'quit' ? 'quit' : 'query-status', 3);
    } else if (response.id === 3) { console.log(action === 'quit' ? 'QUIT_ACCEPTED' : response.return?.status); finish(0); }
  }
});
socket.on('end', () => { if (!done) finish(action === 'quit' && step === 3 ? 0 : 1); });
