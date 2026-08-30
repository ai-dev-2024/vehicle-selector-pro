// Records the automated 2.5-min walkthrough of demo/index.html as a real
// screen video using Playwright's built-in screencast (1280x720).
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const OUT_DIR = path.join(__dirname, 'video_v3');
const URL = process.env.DEMO_URL || 'http://127.0.0.1:8899/index.html';
const DURATION_MS = parseInt(process.env.DURATION_MS || '154000', 10);

(async () => {
  fs.rmSync(OUT_DIR, { recursive: true, force: true });
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
    deviceScaleFactor: 1,
    recordVideo: { dir: OUT_DIR, size: { width: 1280, height: 720 } },
  });
  const page = await context.newPage();

  page.on('console', m => { if (m.type() === 'error') console.log('[console.error]', m.text().slice(0, 200)); });
  page.on('pageerror', e => console.log('[pageerror]', String(e).slice(0, 300)));

  await page.goto(URL, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);

  // Drive the existing automated walkthrough (virtual cursor, timed cues).
  await page.evaluate(() => startAutomatedDemo());

  // Record for the full scripted duration.
  await page.waitForTimeout(DURATION_MS);

  await context.close(); // finalizes the video
  await browser.close();

  const files = fs.readdirSync(OUT_DIR).filter(f => f.endsWith('.webm'));
  if (!files.length) { console.error('NO VIDEO PRODUCED'); process.exit(1); }
  const src = path.join(OUT_DIR, files[0]);
  const dst = path.join(OUT_DIR, 'walkthrough.webm');
  fs.renameSync(src, dst);
  console.log('SAVED', dst, fs.statSync(dst).size, 'bytes');
})().catch(e => { console.error(e); process.exit(1); });
