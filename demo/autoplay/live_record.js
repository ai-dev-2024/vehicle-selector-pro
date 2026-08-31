// Records a narrated live tour of the DEPLOYED app (vehicle-selector-pro.fly.dev)
// as a continuous screen recording, driving real interactions (cascade filter,
// Find Parts, product PDP, garage, admin) on a strict timestamp.
// Outputs raw webm via Playwright screencast; audio is assembled separately.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE = 'https://vehicle-selector-pro.fly.dev';
const OUT_DIR = path.join(__dirname, 'video_live');
const OUT_JSON = path.join(__dirname, 'live_schedule.json');

fs.rmSync(OUT_DIR, { recursive: true, force: true });
fs.mkdirSync(OUT_DIR, { recursive: true });

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    recordVideo: { dir: OUT_DIR, size: { width: 1280, height: 720 } },
  });
  const page = await context.newPage();
  page.on('console', m => { if (m.type() === 'error') console.log('[c]', m.text().slice(0, 140)); });
  page.on('pageerror', e => console.log('[p]', String(e).slice(0, 140)));

  const scenes = [
    { id: 'home',       at: 1500,  len: 6500,  run: async () => { await page.goto(BASE + '/demo', { waitUntil: 'domcontentloaded' }); } },
    { id: 'cascade',    at: 8000,  len: 9500,  run: async () => {
        await page.selectOption('.vsp-select-year', { label: '2023' }); await sleep(900);
        await page.selectOption('.vsp-select-make', { label: 'Ford' }); await sleep(900);
        await page.selectOption('.vsp-select-model', { label: 'F-150' }); await sleep(1200);
    } },
    { id: 'collection', at: 17500, len: 13500, run: async () => {
        await page.click('.vsp-btn-search');
        await page.waitForLoadState('domcontentloaded').catch(()=>{});
    } },
    { id: 'pdp',        at: 31000, len: 12500, run: async () => {
        const href = await page.$eval('a[href*="/products/"]', a => a.getAttribute('href')).catch(()=>null);
        if (href) await page.goto(BASE + href, { waitUntil: 'domcontentloaded' });
    } },
    { id: 'garage',     at: 43500, len: 10000, run: async () => { await page.goto(BASE + '/demo/garage', { waitUntil: 'domcontentloaded' }); } },
    { id: 'admin',      at: 53500, len: 12000, run: async () => { await page.goto(BASE + '/demo/admin', { waitUntil: 'domcontentloaded' }); } },
    { id: 'fitments',   at: 65500, len: 11000, run: async () => { await page.goto(BASE + '/demo/admin/fitments', { waitUntil: 'domcontentloaded' }); } },
    { id: 'outro',      at: 76500, len: 9000,  run: async () => { await page.goto(BASE + '/demo', { waitUntil: 'domcontentloaded' }); } },
  ];

  const start = Date.now();
  const TOTAL = 86500;
  const endAt = start + TOTAL;
  const measured = {};
  for (const s of scenes) {
    const sStart = start + s.at;
    if (Date.now() < sStart) await sleep(sStart - Date.now());
    measured[s.id] = Date.now() - start; // true wall-clock start of this scene
    await s.run();
    const sEnd = sStart + s.len;
    if (Date.now() < sEnd) await sleep(sEnd - Date.now());
  }
  if (Date.now() < endAt) await sleep(endAt - Date.now());

  await context.close(); // finalizes the video
  await browser.close();

  const files = fs.readdirSync(OUT_DIR).filter(f => f.endsWith('.webm'));
  if (!files.length) { console.error('NO VIDEO'); process.exit(1); }
  const src = path.join(OUT_DIR, files[0]);
  const dst = path.join(OUT_DIR, 'live-tour.webm');
  fs.renameSync(src, dst);
  console.log('SAVED', dst, fs.statSync(dst).size, 'bytes');

  // Write the scene schedule (offset_ms + id) for audio assembly.
  const sched = { base: BASE, totalMs: TOTAL, scenes: scenes.map(s => ({ id: s.id, atMs: measured[s.id] ?? s.at, lenMs: s.len, plannedAtMs: s.at })) };
  fs.writeFileSync(OUT_JSON, JSON.stringify(sched, null, 2));
  console.log('SCHEDULE', OUT_JSON, 'scenes', scenes.length);
})().catch(e => { console.error('ERR', e); process.exit(1); });