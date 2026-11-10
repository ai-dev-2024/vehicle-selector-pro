#!/usr/bin/env node
// Self-check for the storefront widget. No dependencies:
//   node scripts/check_vehicle_selector.js
//
// Loads extensions/.../assets/vehicle-selector.js against a minimal fake DOM
// and fails if text from the API or localStorage reaches innerHTML unescaped,
// or if loading the file twice initialises the widget twice.
const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

// An optional argument points the check at another copy of the file.
const source = fs.readFileSync(
  process.argv[2] || path.join(__dirname, '../extensions/vehicle-selector-pro-extension/assets/vehicle-selector.js'),
  'utf8'
);

const PAYLOAD = '"><img src=x onerror=alert(1)>';

function element(children = {}) {
  const handlers = {};
  return {
    innerHTML: '', value: '', disabled: false, className: '', textContent: '', dataset: {}, style: {},
    classList: { toggle() {}, add() {}, remove() {}, contains: () => false },
    addEventListener(type, fn) { (handlers[type] = handlers[type] || []).push(fn); },
    fire(type, event = { stopPropagation() {}, target: { classList: { contains: () => false } } }) {
      return Promise.all((handlers[type] || []).map(fn => fn(event)));
    },
    querySelector: selector => children[selector] || null,
    querySelectorAll: () => []
  };
}

function buildPage({ activeVehicle, garage } = {}) {
  const selects = {
    '.vsp-select-year': element(), '.vsp-select-make': element(), '.vsp-select-model': element(),
    '.vsp-select-trim': element(), '.vsp-select-engine': element(),
    '.vsp-btn-search': element(), '.vsp-btn-reset': element(),
    '.vsp-garage-btn': element(), '.vsp-garage-dropdown': element()
  };
  const widget = element(selects);
  const badge = element();
  badge.dataset.productId = 'gid://shopify/Product/1';
  const bySelector = {
    '.vsp-widget-container': [widget],
    '.vsp-pdp-fitment-badge': [badge],
    '.vsp-garage-dropdown': [selects['.vsp-garage-dropdown']]
  };

  const store = new Map();
  if (activeVehicle) store.set('vsp_active_vehicle', JSON.stringify(activeVehicle));
  if (garage) store.set('vsp_customer_garage', JSON.stringify(garage));

  const requests = [];
  const responses = {
    years: { success: true, years: [PAYLOAD] },
    makes: { success: true, makes: [PAYLOAD] },
    check_fitment: { success: true, data: { fits: true, fitment_type: 'direct_fit', notes: PAYLOAD } }
  };

  const sandbox = {
    console: { warn() {}, error() {} },
    URLSearchParams,
    CustomEvent: class { constructor(type, init) { this.type = type; Object.assign(this, init); } },
    localStorage: {
      getItem: key => (store.has(key) ? store.get(key) : null),
      setItem: (key, value) => store.set(key, String(value)),
      removeItem: key => store.delete(key)
    },
    document: {
      readyState: 'complete',
      addEventListener() {},
      querySelectorAll: selector => bySelector[selector] || []
    },
    fetch: async url => {
      const endpoint = url.split('?')[0].split('/').pop();
      requests.push(endpoint);
      return { ok: true, json: async () => responses[endpoint] || { success: false } };
    },
    location: { pathname: '/products/part', hostname: 'shop.example' },
    addEventListener() {},
    dispatchEvent() {}
  };
  sandbox.window = sandbox;
  vm.createContext(sandbox);
  return { sandbox, selects, badge, requests };
}

const settle = () => new Promise(resolve => setImmediate(resolve));
const load = sandbox => vm.runInContext(source, sandbox);

function assertEscaped(html, where) {
  assert.ok(html.length > 0, `${where}: expected rendered markup`);
  assert.ok(!html.includes('<img'), `${where}: unescaped markup reached innerHTML -> ${html}`);
  assert.ok(html.includes('&lt;img'), `${where}: expected the value to be rendered as escaped text`);
}

(async () => {
  // 1. Dropdown options built from API responses are escaped.
  let page = buildPage();
  load(page.sandbox);
  await settle();
  assertEscaped(page.selects['.vsp-select-year'].innerHTML, 'year options');

  page.selects['.vsp-select-year'].value = '2024';
  await page.selects['.vsp-select-year'].fire('change');
  assertEscaped(page.selects['.vsp-select-make'].innerHTML, 'make options');

  // 2. The product badge escapes fitment notes (API) and the vehicle name (localStorage).
  page = buildPage({ activeVehicle: { year: '2024', make: 'Ford', model: 'F-150', display_name: PAYLOAD } });
  load(page.sandbox);
  await settle();
  await settle();
  assertEscaped(page.badge.innerHTML, 'fitment badge');

  // 3. The garage dropdown escapes saved vehicles (localStorage).
  page = buildPage({ garage: [{ year: '2024', make: PAYLOAD, model: 'F-150', trim: PAYLOAD, display_name: 'x' }] });
  load(page.sandbox);
  await settle();
  await page.selects['.vsp-garage-btn'].fire('click');
  assertEscaped(page.selects['.vsp-garage-dropdown'].innerHTML, 'garage dropdown');

  // 4. Loading the file twice (two app blocks on one page) initialises once.
  page = buildPage();
  load(page.sandbox);
  load(page.sandbox);
  await settle();
  assert.strictEqual(page.requests.filter(r => r === 'years').length, 1, 'widget initialised more than once');

  console.log('vehicle-selector.js: 4 checks passed');
})().catch(error => {
  console.error(error.message);
  process.exit(1);
});
