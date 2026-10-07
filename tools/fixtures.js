// Dumps game data and reference values from the tested web build for the native port.
const { chromium } = require('playwright');
const fs = require('fs'); const path = require('path');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + path.join(__dirname, 'out2', 'page.html'));
  const out = await p.evaluate(() => {
    const ww = __ww; const o = {};
    o.EL = ww.EL; o.ITEM = ww.ITEM; o.ISL = ww.ISL; o.SPL = ww.SPL; o.ART = ww.ART;
    const fnv = (arrs) => { let h = 0x811c9dc5; arrs.forEach(a => { for (let i = 0; i < a.length; i++) { h ^= a[i] & 255; h = Math.imul(h, 0x01000193) >>> 0; } }); return h >>> 0; };
    o.maps = [];
    [1, 2, 3, 12345, 987654321, 4000000000].forEach(seed => { for (let isle = 0; isle < 4; isle++) { const m = ww.makeMap((seed + isle * 104729) >>> 0, isle); let vsum = 0; for (let i = 0; i < m.vary.length; i++) vsum += Math.round(m.vary[i] * 1000); o.maps.push({ seedIn: (seed + isle * 104729) >>> 0, isle, seed: m.seed, start: m.start, shrine: m.shrine, camps: m.camps, counts: m.tilesBy.map(t => t.length), mainCount: m.mainCount, hash: fnv([m.biome, m.block, m.main, m.isCamp]), vsum }); } });
    o.stats = []; ['plipple', 'oldscarp', 'skyvane', 'whiffet'].forEach(sp => [1, 5, 9, 20, 40].forEach(L => [false, true].forEach(g => { const c = { sp, level: L, grown: g && !!ww.SP[sp].g }; o.stats.push({ sp, level: L, grown: c.grown, hp: ww.stat(c, 'hp'), atk: ww.stat(c, 'atk'), def: ww.stat(c, 'def'), spd: ww.stat(c, 'spd') }); })));
    o.need = [1, 5, 8, 9, 10, 20, 30, 39].map(L => [L, ww.need(L)]);
    o.damage = []; [['plipple', 5, 'whiffet', 3, 10, null, false, 0.5], ['plipple', 5, 'pebbrix', 4, 13, 'tide', false, 0.0], ['skyvane', 40, 'cryolith', 32, 21, 'gale', true, 0.999], ['burrbit', 12, 'cindrel', 14, 13, 'thorn', false, 0.25], ['whiffet', 1, 'oldscarp', 40, 10, null, true, 0.1]].forEach(a => { o.damage.push({ a: a[0], al: a[1], d: a[2], dl: a[3], pow: a[4], el: a[5], braced: a[6], rnd: a[7], out: ww.damage(ww.mkWild(a[0], a[1]), ww.mkWild(a[2], a[3]), a[4], a[5], a[6], a[7]) }); });
    return o;
  });
  // mulberry32 reference
  out.rng = await p.evaluate(() => { function mulberry32(a) { return function () { a |= 0; a = a + 0x6D2B79F5 | 0; var t = Math.imul(a ^ a >>> 15, 1 | a); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296 } } return [42, 0, 4294967295, 2654435761].map(s => { const r = mulberry32(s); return { seed: s, v: [r(), r(), r(), r(), r()].map(x => Math.round(x * 4294967296)) }; }); });
  fs.writeFileSync(path.join(__dirname, 'fixtures.json'), JSON.stringify(out));
  console.log('maps', out.maps.length, 'species', out.SPL.length, JSON.stringify(out.rng[0]), JSON.stringify(out.maps[0]));
  await b.close();
})();
