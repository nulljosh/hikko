import { chromium } from 'playwright';
import fs from 'fs';
const src = fs.readFileSync(new URL('file://' + process.cwd() + '/onboarding.js')).toString();
const b = await chromium.launch();
const p = await b.newPage();
await p.route('**/ob-test', r => r.fulfill({ contentType: 'text/html', body: '<body style="--bg:#111;--text:#eee;--accent:#3B82F6"></body>' }));
await p.goto('http://ob.test/ob-test');
await p.addScriptTag({ content: src });
const out = await p.evaluate(() => Onboarding.start({key:'t', signedIn:false, slides:[{title:'x',body:'y'}]}));
console.assert(out === false, 'signed-out suppressed');
const shown = await p.evaluate(() => Onboarding.start({
  key:'t', signedIn:true, finishLabel:'Go',
  slides:[{title:'One',body:'first'},{title:'Two',body:'second'}]
}));
console.assert(shown === true, 'should show');
console.assert(await p.textContent('.ob-h') === 'One');
console.assert((await p.$$('.ob-dot')).length === 2);
console.assert(await p.textContent('.ob-next') === 'Next');
await p.click('.ob-next');
console.assert(await p.textContent('.ob-h') === 'Two');
console.assert(await p.textContent('.ob-next') === 'Go');
await p.screenshot({ path: '/tmp/claude-501/-Users-joshua/f29eb9b0-30f8-4c0c-b8d6-50a09e28d9fa/scratchpad/ob.png' });
await p.click('.ob-next');
console.assert((await p.$$('.ob-veil')).length === 0, 'closed');
console.assert(await p.evaluate(() => localStorage.getItem('t_onboarded')) === '1');
const again = await p.evaluate(() => Onboarding.start({key:'t',signedIn:true,slides:[{title:'x',body:'y'}]}));
console.assert(again === false, 'second run suppressed');
// Signed out at load, session appears later: the poll shows it once sign-up lands.
await p.evaluate(() => Onboarding.start({key:'w',slides:[{title:'Hi',body:'y'}]}));
await p.evaluate(() => localStorage.setItem('w_token','abc'));
await p.waitForSelector('.ob-veil', { timeout: 3000 });
console.assert(await p.textContent('.ob-h') === 'Hi', 'shown after sign-up');
// Old Supabase account already signed in at load: stamped, never shown.
await p.evaluate(() => localStorage.setItem('sb-x-auth-token', JSON.stringify({user:{created_at:'2020-01-01T00:00:00Z'}})));
const old = await p.evaluate(() => Onboarding.start({key:'o',slides:[{title:'x',body:'y'}]}));
console.assert(old === false && await p.evaluate(() => localStorage.getItem('o_onboarded')) === '1', 'old account stamped');
await b.close();
console.log('ALL PASS');
