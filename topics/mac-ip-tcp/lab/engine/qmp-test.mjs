import test from 'node:test';
import assert from 'node:assert/strict';
import net from 'node:net';
import fs from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
const helper=fileURLToPath(new URL('./qmp.mjs',import.meta.url));
const root=fileURLToPath(new URL('../.state/qmp-test/',import.meta.url));
await fs.mkdir(root,{recursive:true});
async function run(socket, name, action){
  return new Promise((resolve,reject)=>{
    const p=spawn(process.execPath,[helper,socket,name,action]); let output='';
    p.stdout.on('data',x=>output+=x); p.stderr.on('data',x=>output+=x);
    p.on('error',reject); p.on('exit',code=>resolve({code,output}));
  });
}
for(const scenario of ['status','quit','wrong-owner']){
  test(`QMP ${scenario}`,async()=>{
    const sock=path.join(root,`${scenario}.sock`); await fs.rm(sock,{force:true});
    const clients=new Set();
    const server=net.createServer(c=>{
      clients.add(c); c.on('close',()=>clients.delete(c)); c.on('error',()=>{});
      c.write(JSON.stringify({QMP:{version:{qemu:{major:11,minor:1,micro:0}},capabilities:[]}})+'\r\n');
      let buffer='';
      c.on('data',chunk=>{
        buffer+=chunk;
        while(buffer.includes('\n')){
          const idx=buffer.indexOf('\n'); const msg=JSON.parse(buffer.slice(0,idx)); buffer=buffer.slice(idx+1);
          let result={};
          if(msg.execute==='query-name') result={name:'owned-test-vm'};
          if(msg.execute==='query-status') result={status:'running',running:true};
          c.write(JSON.stringify({return:result,id:msg.id})+'\r\n');
        }
      });
    });
    await new Promise(resolve=>server.listen(sock,resolve));
    try{
      const out=await run(sock,scenario==='wrong-owner'?'not-owner':'owned-test-vm',scenario==='quit'?'quit':'status');
      assert.equal(out.code,scenario==='wrong-owner'?3:0,out.output);
      assert.match(out.output,scenario==='wrong-owner'?/ownership mismatch/:scenario==='quit'?/QUIT_ACCEPTED/:/running/);
    }finally{
      for(const c of clients)c.destroy();
      await new Promise(resolve=>server.close(resolve)); await fs.rm(sock,{force:true});
    }
  });
}
