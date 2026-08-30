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
   - Deployed on Fly.io: https://vehicle-selector-pro.fly.dev (Puma + Sidekiq + Postgres + private Redis).
   - Installed via OAuth on a real Shopify development store with 7 demo products; fitment metafields verified on all products.
   - Full evidence trail in [`REQUIREMENTS-VERIFICATION.md`](REQUIREMENTS-VERIFICATION.md).

3. **Demo Assets**:
   - `/storefront_preview` (development-only harness) renders the production Theme App Extension widget against the live API — cascading filters, collection results, and PDP fitment badges.
   - Narrated 2.5-minute walkthrough video in `demo/video/` with the matching script in [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md).

4. **Production Documentation**:
   - Comprehensive [`README.md`](README.md) with system architecture diagrams, database ERDs, API endpoint reference, and step-by-step setup.
   - [`docs/SETUP.md`](docs/SETUP.md) — local development guide
   - [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md) — verified Fly.io runbook incl. real incident table

---

## 🎤 Client Demonstration Script & Presentation Guide (2–3 Minutes)

Use this structured script when presenting the solution to stakeholders or clients:

```text
[0:00 - 0:25] Introduction & Multi-Tenant Architecture
"Hello! Today I'm presenting Vehicle Selector Pro, a production-grade Shopify application built with Ruby on Rails 7 and modern Online Store 2.0 Theme App Extensions. It is designed to handle high-volume automotive parts catalogs with complex Year, Make, Model, Trim, and Engine fitment rules."

[0:25 - 0:55] Storefront Cascading Filters & Performance
"On the storefront, the customer interacts with our Theme App Extension block. Notice how selecting the Year instantly cascades to available Makes, Models, Trims, and Engines. All lookups route through our Shopify App Proxy with per-shop cached queries, so the dropdowns stay snappy even on large catalogs."

[0:55 - 1:25] Collection Filtering & 'My Garage' Customer Wallet
"When the customer clicks 'Search Compatible Parts', the collection page instantly filters to compatible products using Shopify's native metafield filter tokens. Furthermore, our 'My Garage' feature saves the customer's vehicle in LocalStorage, allowing them to switch between vehicles in their household effortlessly."

[1:25 - 1:55] Product Detail Page (PDP) Fitment Guarantee Badge
"On individual product detail pages, our dynamic Fitment Badge evaluates compatibility in real time. Matching parts display a green 'Guaranteed Exact Fit' badge with specific installation notes. Incompatible parts show a clear 'Does NOT Fit' warning, and universal accessories display a 'Universal Fitment' badge—drastically reducing return rates and customer confusion."

[1:55 - 2:25] Polaris Merchant Admin & GraphQL Metafield Sync
"In the Shopify Admin, merchants get a Polaris-styled dashboard with a full Product Fitment Matrix, YMM Vehicle Database explorer, and Bulk CSV Importer for uploading thousands of compatibility mappings. When fitment changes occur, our asynchronous Sidekiq background jobs batch-sync data to Shopify's GraphQL Admin API using the 'metafieldsSet' mutation."

[2:25 - 2:30] Security, Testing & Production Readiness
"All App Proxy and webhook requests are verified using HMAC-SHA256 signatures with constant-time comparison, and both our unit and full-stack integration suites pass with zero errors. The application is deployed and production-ready."
```

---

## 🏛️ Technical Specifications Summary

- **Framework**: Ruby on Rails 7.1 (Ruby >= 3.2.0)
- **Database**: PostgreSQL (Production) / SQLite3 (Development & CI)
- **Background Jobs**: Sidekiq 7 + Redis with exponential backoff for GraphQL rate-limiting
- **Shopify API Version**: `2025-07` (GraphQL Admin API); app-owned metafield definitions in `shopify.app.toml`
- **App Proxy Security**: HMAC-SHA256 verification via constant-time comparison (`ActiveSupport::SecurityUtils.secure_compare`)
- **Theme Extension**: Zero ScriptTag API usage; 100% Theme App Extension (OS 2.0) compliant.
