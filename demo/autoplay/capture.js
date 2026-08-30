const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const SHOWCASE = 'file:///' + path.join(__dirname, 'showcase.html').replace(/\\/g, '/');
const OUT_DIR = path.join(__dirname, 'frames');

const scenes = [
  { id: 'scene1', name: '01_hero', title: 'Vehicle Selector Pro', narrate: 'Vehicle Selector Pro. A production Shopify application for automotive and specialty-parts merchants. Customers filter by Year, Make, Model, Trim, and Engine, and see Guaranteed Exact Fit badges on product pages.' },
  { id: 'scene2', name: '02_storefront', title: 'Cascading Storefront Filters', narrate: 'On the storefront, customers pick their vehicle. Year cascades into Make, Model, Trim, and Engine. Every selection narrows results instantly, powered by HMAC-signed App Proxy queries with sub-15 millisecond response times.' },
  { id: 'scene3', name: '03_pdp', title: 'Product Fitment Badge', narrate: 'On the product page, a Guaranteed Exact Fit badge confirms compatibility in real time. Incompatible parts show a clear Does NOT Fit warning, reducing returns and support tickets.' },
  { id: 'scene4', name: '04_admin', title: 'Merchant Admin Dashboard', narrate: 'Merchants manage fitment rules, vehicle library, and bulk imports from a Polaris-styled dashboard. Sidekiq syncs changes to Shopify Product Metafields in batches of 25.' },
  { id: 'scene5', name: '05_architecture', title: 'Production Architecture', narrate: 'Multi-tenant by design. Every request verified with HMAC-SHA-256. Metafields synced via GraphQL. Deployed on Fly.io with PostgreSQL, Redis, and Sidekiq. Production ready.' },
];

(async () => {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 } });

  // Load the showcase page
  const page = await context.newPage();
  await page.goto(SHOWCASE, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  const manifest = [];

  for (const scene of scenes) {
    // Show this scene, hide others
    await page.evaluate((id) => {
      document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
      document.getElementById(id).classList.add('active');
    }, scene.id);

    await page.waitForTimeout(300);

    const outPath = path.join(OUT_DIR, `${scene.name}.png`);
    await page.screenshot({ path: outPath, fullPage: false });
    console.log(`CAPTURED ${scene.name}`);

    manifest.push({
      name: scene.name,
      title: scene.title,
      narrate: scene.narrate,
      img: outPath,
    });
  }

  await browser.close();

  fs.writeFileSync(path.join(__dirname, 'manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(`\nDone. ${manifest.length} screenshots captured.`);
})();
