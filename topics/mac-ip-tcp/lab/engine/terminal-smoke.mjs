import {spawn} from 'node:child_process';
import {EventEmitter} from 'node:events';
import fs from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const base=fileURLToPath(new URL('../',import.meta.url));
function pc(role){
  const process=spawn(path.join(base,'lab'),['pc',role],{cwd:base,stdio:['pipe','pipe','pipe']});
  const state={process,output:'',events:new EventEmitter(),role,ended:false};
  for(const stream of [process.stdout,process.stderr])stream.on('data',data=>{state.output+=data.toString();state.events.emit('update');});
  process.on('exit',code=>{state.ended=true;state.code=code;state.events.emit('update');});
  process.on('error',error=>{state.error=error;state.events.emit('update');});
  return state;
}
function wait(state,text,start=0,ms=15000){
  return new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>finish(new Error(`${state.role}: did not see ${text}`)),ms);
    const finish=error=>{clearTimeout(timer);state.events.off('update',check);error?reject(error):resolve();};
    const check=()=>{
      if(state.output.slice(start).includes(text))finish();
      else if(state.error||state.ended)finish(state.error||new Error(`${state.role} exited ${state.code} before ${text}`));
    };
    state.events.on('update',check);check();
  });
}
function exited(state){
  if(state.ended)return Promise.resolve();
  return new Promise((resolve,reject)=>{
    const timer=setTimeout(()=>reject(new Error(`${state.role} did not exit`)),10000);
    state.process.once('exit',()=>{clearTimeout(timer);resolve();});
  });
}
const a=pc('a'),b=pc('b');
try{
  await Promise.all([wait(a,'Run lab-help'),wait(b,'Run lab-help')]);
  b.process.stdin.write('capture-start\n'); await wait(b,'Capture ready:');
  b.process.stdin.write('listen echo\n'); await wait(b,'LISTEN 10.77.2.2:18080');
  a.process.stdin.write("routes\nhops\nping-peer\nsend 'two-terminal-test'\n");
  await wait(a,'SUCCESS');
  if(!a.output.includes('via 10.77.1.1')||!a.output.includes('0% packet loss'))throw new Error('A route/ping evidence missing');
  await wait(b,'RECEIVED bytes=17');
  let checkpoint=b.output.length;b.process.stdin.write('\x03');await wait(b,'[PC-B 10.77.2.2]',checkpoint);
  checkpoint=b.output.length;b.process.stdin.write('capture-stop\n');await wait(b,'Flags [S.]',checkpoint);
  a.process.stdin.write('exit\n');b.process.stdin.write('exit\n');
  await Promise.all([exited(a),exited(b)]);
  if(a.code!==0||b.code!==0)throw new Error(`shell exit codes ${a.code},${b.code}`);
  console.log('PASS actual PC-A/PC-B interactive shells, ping, routes, hops, echo, background handshake capture, clean exit');
}finally{
  for(const state of [a,b]){
    if(!state.ended){state.process.stdin.write('\x03exit\n');state.process.kill('SIGTERM');}
  }
  const logDir=path.join(base,'.state','test-results','terminals');
  await fs.mkdir(logDir,{recursive:true});
  for(const state of [a,b])await fs.writeFile(path.join(logDir,`terminal-${state.role}.log`),state.output);
}
