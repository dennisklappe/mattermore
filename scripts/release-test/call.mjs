import {chromium} from 'playwright';
const URL=process.env.MM_URL||'http://localhost:18065';
const b=await chromium.launch({args:['--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream']});
async function user(name){
  const ctx=await b.newContext({viewport:{width:1400,height:900},permissions:['microphone','camera']});
  await ctx.addInitScript(()=>{try{localStorage.setItem('__landingPageSeen__','true');localStorage.setItem('BypassLandingPage','true')}catch(e){}});
  const p=await ctx.newPage(); p.on('pageerror',e=>console.log(name,'pageerror',e.message.slice(0,150)));
  await p.goto(URL+'/login'); await p.click('text=View in Browser').catch(()=>{});
  await p.fill('#input_loginId',name); await p.fill('#input_password-input','Passw0rd1234!'); await p.click('#saveSetting');
  await p.waitForTimeout(4000);
  await p.goto(URL+'/t1/channels/town'); await p.waitForTimeout(4000);
  await p.click('text=No thanks, I\'ll figure it out myself').catch(()=>{});
  return p;
}
const [a,u1,u2]=await Promise.all([user('admin'),user('u1'),user('u2')]);
await a.click('text=Start call'); await a.waitForTimeout(6000);
await a.screenshot({path:'call-a.png'});
for (const [n,p] of [['u1',u1],['u2',u2]]) {
  const j=p.locator('text=Join call').first();
  console.log(n,'join visible:',await j.isVisible().catch(()=>false));
  await j.click().catch(e=>console.log(n,'join click failed',e.message.slice(0,100)));
  await p.waitForTimeout(5000);
}
await a.waitForTimeout(4000);
await a.screenshot({path:'call-a2.png'}); await u2.screenshot({path:'call-u2.png'});
const w=await a.locator('#calls-widget').innerText().catch(()=>'NO WIDGET');
console.log('widget text:',JSON.stringify(w.slice(0,300)));
console.log('widget profiles (avatars):',await a.locator('#calls-widget .calls-widget-profiles > *').count().catch(()=>-1));
await b.close();
