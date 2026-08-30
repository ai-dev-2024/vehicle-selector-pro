# Client Delivery & Presentation Package: Vehicle Selector Pro

**Project**: Vehicle Selector Pro (Shopify Automotive Fitment & Storefront Engine)  
**Deliverable Version**: Production 1.0  
**Stack**: Ruby on Rails 7.1, Shopify Theme App Extension (Liquid + ES6 JS), Shopify GraphQL Admin API, PostgreSQL / SQLite3, Redis / Sidekiq, Polaris UI  
**GitHub Repository**: [https://github.com/ai-dev-2024/vehicle-selector-pro](https://github.com/ai-dev-2024/vehicle-selector-pro)  
**Deployment Target**: Fly.io (https://vehicle-selector-pro.fly.dev)

---

## 🌟 Executive Summary

Vehicle Selector Pro is an enterprise-grade Shopify application engineered to solve the complex automotive Year-Make-Model-Trim-Engine (YMMTE) fitment problem for merchants.

By combining a **normalized, high-speed multi-tenant local cache** with **Shopify Product Metafield synchronization** (app-owned `$app.vehicle_fitment` metafields via GraphQL `metafieldsSet`), Vehicle Selector Pro delivers cached storefront filtering, guaranteed fitment badges on product detail pages (PDP), and customer vehicle wallets ("My Garage") without impacting store performance or using deprecated ScriptTag APIs.

---

## 📦 Key Deliverables Included

1. **Source Code & Git Repository**:
   - Complete Rails 7.1 application with ActiveRecord multi-tenant models, controllers, background workers, and service objects.
   - Shopify Theme App Extension with Liquid blocks (`blocks/vehicle_selector_filter.liquid`, `blocks/product_fitment_badge.liquid`) and vanilla JavaScript client (`assets/vehicle-selector.js`).
   - Two automated test suites: isolated unit harness (11 runs / 35 assertions) and full-stack integration tests that boot the real app and issue HTTP requests (9 runs / 28 assertions) — all passing.

2. **Live Deployment & Verification**:
    - **Health check:** `https://vehicle-selector-pro.fly.dev/up` → `{"status":"ok"}` (Fly: `iad`, Puma + Sidekiq + Postgres + private Redis `vsp-redis`)
    - **Installation:** `https://vehicle-selector-pro.fly.dev/login?shop=your-store.myshopify.com` (OAuth `shopify_app` 22.0, tokens encrypted)
    - **Daily access:** After installation, access via Shopify Admin → Apps → Vehicle Selector Pro (no separate login needed)
    - Installed via OAuth on real dev store `vehicle-selector-pro.myshopify.com` with 7 products / 35 fitments; `$app.vehicle_fitment` read-back verified 7/7
    - Full evidence trail in [`REQUIREMENTS-VERIFICATION.md`](REQUIREMENTS-VERIFICATION.md).

3. **Demo Assets — what to submit:**
   - **Recorded video (2.5 min, narrated):** [`demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm`](demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm) — also at `https://github.com/ai-dev-2024/vehicle-selector-pro/blob/main/demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm` (raw: `/raw/main/...`) + script [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) · poster `demo/video/frame-000.png`
   - `/storefront_preview` (dev harness) + `admin_preview` render the real extension widget against live API for local re-recording via `npm run capture` (puppeteer)
   - `demo/index.html` — Play 2.5-min walkthrough button (Web Speech API + tab capture)

4. **Production Documentation**:
   - Clean [`README.md`](README.md) — features, quick start, tech stack, links to all docs
   - [`docs/SETUP.md`](docs/SETUP.md) — local development guide
   - [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — verified Fly.io runbook incl. real incident table
   - [`docs/API.md`](docs/API.md) — App Proxy endpoints, webhook topics, metafield schema
   - [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — system diagrams, data model, request flow

---

## Client Demonstration Script & Presentation Guide (2–3 Minutes)

Use the professional voiceover script in [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) when presenting the solution to stakeholders or clients. The script includes:

- **Scene-by-scene narration** with timestamps and screen directions
- **Continuous read version** for single-take recording
- **Recording setup** recommendations (OBS Studio + mic, or Loom)

The 2.5-minute demo video is at [`demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm`](demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm) — [watch on GitHub](https://github.com/ai-dev-2024/vehicle-selector-pro/blob/main/demo/video/Vehicle_Selector_Pro_2.5min_Demo.webm).

---

## 🏛️ Technical Specifications Summary

- **Framework**: Ruby on Rails 7.1 (Ruby >= 3.2.0)
- **Database**: PostgreSQL (Production) / SQLite3 (Development & CI)
- **Background Jobs**: Sidekiq 7 + Redis with exponential backoff for GraphQL rate-limiting
- **Shopify API Version**: `2025-07` (GraphQL Admin API); app-owned metafield definitions in `shopify.app.toml`
- **App Proxy Security**: HMAC-SHA256 verification via constant-time comparison (`ActiveSupport::SecurityUtils.secure_compare`)
- **Theme Extension**: Zero ScriptTag API usage; 100% Theme App Extension (OS 2.0) compliant.
