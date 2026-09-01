<div align="center">

<img src="docs/assets/banner.svg" alt="Vehicle Selector Pro" width="100%">

# Vehicle Selector Pro

### Fitment intelligence for Shopify automotive stores

[![Live Demo](https://img.shields.io/badge/Live_Storefront_Demo-008060?style=flat-square&logo=shopify&logoColor=white)](https://vehicle-selector-pro.fly.dev/demo)
[![Admin Preview](https://img.shields.io/badge/Live_Admin_Preview-1f6feb?style=flat-square)](https://vehicle-selector-pro.fly.dev/demo/admin)
[![CI](https://github.com/ai-dev-2024/vehicle-selector-pro/actions/workflows/ci.yml/badge.svg)](https://github.com/ai-dev-2024/vehicle-selector-pro/actions/workflows/ci.yml)
[![GitHub](https://img.shields.io/badge/View_on_GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/ai-dev-2024/vehicle-selector-pro)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Rails](https://img.shields.io/badge/Rails-7.2-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)
[![Buy me a coffee](https://img.shields.io/badge/Buy_me_a_coffee-FF5E5B?style=flat-square&logo=kofi&logoColor=white)](https://ko-fi.com/ai_dev_2024)

</div>

---

Automotive merchants assign **Year / Make / Model / Trim / Engine** fitment data to their products. Customers filter the catalog with cascading dropdowns and see **"Guaranteed Exact Fit"** badges on product pages — powered by Shopify App Proxy, Product Metafields, and a Theme App Extension.

**[Live storefront demo](https://vehicle-selector-pro.fly.dev/demo)** · **[Live admin preview](https://vehicle-selector-pro.fly.dev/demo/admin)** · **[Demo video](#demo)** · **[Setup guide](docs/SETUP.md)** · **[Merchant installation](docs/MERCHANT_INSTALL.md)** · **[Architecture](#architecture)**

<div align="center">

| | | | |
|---|---|---|---|
| **48** YMMTE configurations | **318** verified fitments | **54** mapped products | **25** brands represented |

</div>


> **Installing on your own store** — this is a custom (unlisted) app, so Shopify requires installation through the Partners distribution link. Open an issue or request access and we will generate an install link for your store. The live demo above needs no installation.

---

> **Built entirely with free AI tools.** This project was designed, coded, and documented using no-cost AI assistance end to end — no paid AI models or paid tools were used anywhere in its development. Everything you see was produced with accessible, free tooling, which is why the potential for further growth is so large: with paid, frontier AI models and commercial tooling, this foundation can be extended into a far richer, production-grade solution with ease.
>
> **Built at the ceiling of a consumer notebook.** The entire project — the Rails app, the Shopify wiring, the storefront, the diagrams, this README, and both narrated demo videos — was designed, coded, tested, and rendered on a single machine: an **ASUS ZenBook UX433FA**, a 2018-vintage, **netbook-class consumer laptop** (Intel Core i7-8565U @ 1.80 GHz, 16 GB RAM, Intel UHD 620 integrated graphics — no GPU, no developer workstation, no cloud IDE; every frame of both videos was rendered on the CPU). This is not a developer tool — it is the kind of everyday notebook you would buy for browsing and documents. That ceiling was set by the hardware and free tooling, not by ambition — which is exactly why the headroom is so large, and why the case for allocating proper development hardware (a powerful laptop or workstation with a GPU) is so strong: with the right resources and paid frontier models, the same foundation leaps a level.


---

## Demo

Two narrated walkthroughs — a merchant command-center tour and the shopper experience — cut from the live app against the shop-drawing redesign. Each video has its own distinct voiceover (male for merchants, female for shoppers) and its own music bed, with tight scene pacing — no dead air.

<div align="center">

**▶ Click a poster to play — each walkthrough opens in GitHub's built-in video player:**

| | |
|---|---|
| ![Merchant walkthrough — click to play](demo/vehicle-selector-pro-merchant.mp4)<sup>**▶ Merchant walkthrough** — 1:29, male voiceover</sup> | <a href="https://ai-dev-2024.github.io/vehicle-selector-pro/demo/vehicle-selector-pro-shopper.mp4"><img src="https://ai-dev-2024.github.io/vehicle-selector-pro/demo/vehicle-selector-shopper-poster.jpg" alt="Shopper walkthrough video — click to play" width="100%"></a><sup>**▶ Shopper walkthrough** — 1:35, female voiceover</sup> |

[Video gallery page](https://ai-dev-2024.github.io/vehicle-selector-pro/demo/videos.html) · [Narration script](docs/DEMO_SCRIPT.md) · [Interactive walkthrough](https://ai-dev-2024.github.io/vehicle-selector-pro/demo/index.html) · [Live storefront demo](https://vehicle-selector-pro.fly.dev/demo)

</div>

---
## Features

- **Cascading storefront widget** — Year, Make, Model, Trim, Engine dropdowns driven by HMAC-signed App Proxy queries
- **Product fitment badges** — Guaranteed Exact Fit / Does NOT Fit / Universal Fit on any product page
- **My Garage** — shoppers save multiple vehicles and switch between them across pages
- **OE part-number search** — shoppers find parts by the factory OE number printed on the part they own
- **Merchant admin** — fitment matrix, vehicle library, bulk CSV import, sync monitor, widget settings
- **Storefront analytics** — daily checks, fit rate, and checks-by-make dashboard (7/30/90-day range) reading async daily aggregates
- **Plans & billing** — Free / Pro / Pro Plus tiers via the Shopify Billing API with 14-day trials; plan ceiling gates bulk imports
- **Metafield sync** — fitment JSON synced to `custom.vehicle_fitment` via `metafieldsSet` in batches of 25 (debounced, resilient)
- **Webhook pipeline** — `products/*`, `app/uninstalled`, `shop/update` processed asynchronously via Sidekiq, replay-protected
- **Production-grade ops** — Solid Cache, ETag caching, structured JSON logging, Sentry, CSP headers, deep health checks, ops runbook
- **Multi-tenant** — per-shop data isolation, encrypted tokens, HMAC-SHA256 verification on every request

---

## Screenshots

### Storefront (live demo)

<div align="center">

**Home — cascading Year / Make / Model / Trim / Engine selector with live fitment data and shop-by-category**

<img src="demo/autoplay/frames_live/04_storefront_home.png" alt="Storefront home with catalog header, cascading vehicle selector widget, shop-by-category tiles, and live fitment data" width="100%">

**Vehicle-filtered results — 2023 Ford F-150 with Guaranteed Exact Fit badges**

<img src="demo/autoplay/frames_live/07_storefront_collection.png" alt="Collection page filtered to 2023 Ford F-150 showing matching parts with Guaranteed Exact Fit badges" width="100%">

**Product detail — spec sheet, verified-fitment chips, and live fitment badge**

<img src="demo/autoplay/frames_live/08_storefront_pdp.png" alt="Product detail page with photo, price, engineered features, specifications table, and verified fitment list" width="100%">

**My Garage — vehicles saved across pages in localStorage**

<img src="demo/autoplay/frames_live/09_storefront_garage.png" alt="My Garage page listing the shopper's saved vehicles with the selector widget above" width="100%">

</div>

### Merchant admin (live preview)

<div align="center">

**Dashboard — catalog coverage, mapped products, and live sync status**

<img src="demo/autoplay/frames_live/01_dashboard.png" alt="Admin dashboard with catalog coverage percentage, mapped products, pending/synced fitment counts, and recent sync logs" width="100%">

**Vehicle library — the YMMTE database with cascading filters**

<img src="demo/autoplay/frames_live/02_vehicles.png" alt="Admin vehicle library with 48 Year/Make/Model/Trim/Engine configurations across Ford, Chevrolet, Toyota, Jeep, BMW, RAM, Honda and Subaru" width="100%">

**Product fitment matrix — every product-to-vehicle mapping with sync status**

<img src="demo/autoplay/frames_live/03_fitment_rules.png" alt="Product fitment matrix with 318 product-to-vehicle mappings, direct-fit and universal fits, sync badges, and edit controls" width="100%">

**Widget & Garage configuration**

<img src="demo/autoplay/frames_live/05_settings.png" alt="Widget settings with brand color, selector depth, button labels, and My Garage options" width="100%">

**Bulk CSV import**

<img src="demo/autoplay/frames_live/06_bulk_imports.png" alt="Bulk fitment CSV import with file upload and paste options" width="100%">

**Metafield sync monitor**

<img src="demo/autoplay/frames_live/10_admin_sync.png" alt="Sync monitor showing background metafield synchronization progress" width="100%">

**Storefront analytics — daily checks, fit rate, and checks-by-make**

<img src="demo/autoplay/frames_live/11_admin_analytics.png" alt="Analytics dashboard with fitment checks, fit rate, no-fit counts, daily bar chart, and checks-by-make table" width="100%">

**Plans & billing — Free / Pro / Pro Plus tiers with 14-day trials**

<img src="demo/autoplay/frames_live/12_admin_billing.png" alt="Plans and billing page comparing Free, Pro and Pro Plus tiers with trial buttons" width="100%">

**OE part numbers — per-product factory part-number cross-reference**

<img src="demo/autoplay/frames_live/13_admin_oe_numbers.png" alt="OE numbers page listing factory part numbers per product with CSV import" width="100%">

</div>

Every screenshot above is a live capture of the running app — see the **[live storefront demo](https://vehicle-selector-pro.fly.dev/demo)** and the **[live admin preview](https://vehicle-selector-pro.fly.dev/demo/admin)**.

---

## Architecture

```mermaid
graph TB
    subgraph Storefront ["Shopify Online Store"]
        TAE["Theme App Extension<br/>vehicle_selector_filter.liquid"]
        PFC["Product Fitment Badge<br/>product_fitment_badge.liquid"]
        StoreJS["vehicle-selector.js<br/>LocalStorage Garage + DOM Sync"]
    end

    subgraph Shopify ["Shopify Platform"]
        Proxy["App Proxy<br/>/apps/vehicle-selector"]
        GQL["GraphQL Admin API<br/>metafieldsSet"]
        WH["Webhook Engine"]
    end

    subgraph App ["Vehicle Selector Pro — Fly.io"]
        subgraph ProxyLayer ["App Proxy API (HMAC Verified)"]
            Auth["AppProxySignatureVerifier"]
            Filters["VehicleFiltersController"]
            Fitments["FitmentsController"]
            Cache["Redis Cache"]
        end

        subgraph Admin ["Admin Dashboard"]
            Dashboard["DashboardController"]
            FitCtrl["ProductFitmentsController"]
            Vehicles["VehiclesController"]
            Bulk["BulkImportsController"]
        end

        subgraph Jobs ["Sidekiq Background Jobs"]
            Batch["BatchSyncJob"]
            Product["ProductMetafieldSyncJob"]
            WebhookJobs["Webhooks::*Job"]
        end

        subgraph Data ["PostgreSQL (multi-tenant)"]
            Shop["Shop"]
            Vehicle["Vehicle"]
            Fitment["VehicleProductFitment"]
            SyncLog["MetafieldSyncLog"]
        end
    end

    TAE --> StoreJS
    PFC --> StoreJS
    StoreJS -->|GET /apps/vehicle-selector/*| Proxy
    Proxy --> Auth
    Auth --> Filters
    Auth --> Fitments
    Filters <--> Cache
    Filters <--> Data
    FitCtrl -->|enqueues| Batch
    Batch -->|metafieldsSet| GQL
    WH --> WebhookJobs
    WebhookJobs --> Data
```

Full system diagrams, data model, and request lifecycles: **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**

---

## Quick start

### Try it now — no install required

**[Live storefront demo →](https://vehicle-selector-pro.fly.dev/demo)** — cascading Year/Make/Model/Trim/Engine widget with guaranteed-fit badges against live data.

**[Live admin preview →](https://vehicle-selector-pro.fly.dev/demo/admin)** — dashboard, fitment matrix ([fitments](https://vehicle-selector-pro.fly.dev/demo/admin/fitments)), vehicle library ([vehicles](https://vehicle-selector-pro.fly.dev/demo/admin/vehicles)), widget settings ([settings](https://vehicle-selector-pro.fly.dev/demo/admin/settings)), bulk CSV import ([imports](https://vehicle-selector-pro.fly.dev/demo/admin/imports)), and the sync monitor ([sync](https://vehicle-selector-pro.fly.dev/demo/admin/sync)).

### Local development

```bash
git clone https://github.com/ai-dev-2024/vehicle-selector-pro.git
cd vehicle-selector-pro
bundle install
cp .env.example .env    # fill in SHOPIFY_API_KEY / SHOPIFY_API_SECRET / SHOPIFY_STORE_DOMAIN
bundle exec rails db:prepare
bundle exec rails db:seed
bundle exec rails server
```

Then open `http://localhost:3000/demo` for the public storefront preview, or `http://localhost:3000/demo/admin` for the read-only admin preview. The legacy `/storefront_preview` route is also available in development.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 7.2 |
| Database | PostgreSQL (production) / SQLite (dev) |
| Background jobs | Sidekiq + Redis |
| Shopify integration | Theme App Extension (OS 2.0), App Proxy, GraphQL Admin API (`metafieldsSet`) |
| Security | HMAC-SHA256 verification, Rack::Attack throttling, ActiveRecord Encryption |
| Hosting | Fly.io (Puma + Sidekiq + Postgres + private Redis) |

---

## Roadmap

**Shipped recently** — full history in [CHANGELOG.md](CHANGELOG.md):

- **v1.3.2 — Catalog wave 4 + demo experience** — 20 new products (54 total, 318 fitments) with real photography, a demo billing walkthrough with simulated plan switching, and smoother merchant UI motion
- **v1.3.1 — Rails 7.1.6 → 7.2.3.2 security upgrade** — resolves GHSA-v55j-83pf-r9cq, GHSA-89vf-4333-qx8v and GHSA-2j26-frm8-cmj9 (now removed from the audit whitelist). Plan retained for reference: [docs/RAILS_7_2_UPGRADE_PLAN.md](docs/RAILS_7_2_UPGRADE_PLAN.md)
- **v1.3.0 — Storefront analytics** — daily checks, fit rate, and checks-by-make dashboard with 7/30/90-day ranges
- **v1.2.0 — Shopify Billing** — Free / Pro / Pro Plus tiers with 14-day trials, plan-gated bulk imports
- **v1.1.0 — Production hardening** — Solid Cache, webhook dedup, sync resilience, OE-number cross-reference, fitment confidence scoring, security headers, Sentry

**Planned:**

- **Full billing rollout** — the Shopify Billing API flow (Free / Pro / Pro Plus tiers, 14-day trials, plan-gated imports) is implemented and tested; what remains is flipping `SHOPIFY_BILLING_TEST=false` on a production Partner app and App Store listing approval
- **Supersession chains** — a richer part-catalog engine on top of the shipped OE-number cross-reference
- **Deeper analytics** — per make+model and per-product rollups, conversion lift and drop-off reports on top of the shipped daily aggregates
- **White-label theming** — storefront theming, translation support, deeper widget controls

---

## Documentation

| | |
|---|---|
| [Setup guide](docs/SETUP.md) | Local development environment and public demo routes |
| [Merchant installation](docs/MERCHANT_INSTALL.md) | Safe client handoff, OAuth install and theme setup |
| [Deployment](docs/DEPLOYMENT.md) | Fly.io runbook with provisioning commands |
| [Operations runbook](docs/OPERATIONS.md) | Health checks, backups/restore, monitoring, incidents |
| [API reference](docs/API.md) | App Proxy endpoints, admin endpoints, billing plans, webhook topics |
| [Architecture](docs/ARCHITECTURE.md) | System diagrams and data model (incl. billing, analytics, OE) |
| [Requirements verification](REQUIREMENTS-VERIFICATION.md) | Spec-to-evidence mapping incl. post-spec features |
| [Rails 7.2 upgrade plan](docs/RAILS_7_2_UPGRADE_PLAN.md) | Resolves remaining dependency-audit advisories |
| [Project structure](PROJECT-STRUCTURE.md) | Directory tree and module map |
| [Privacy policy](docs/PRIVACY.md) | GDPR coverage, data inventory, retention (also served at /privacy) |
| [App Store submission](docs/APP_STORE_SUBMISSION.md) | Partners Dashboard steps, listing copy, review notes |
| [Demo script](docs/DEMO_SCRIPT.md) | Voiceover narration for the walkthrough video |
| [Changelog](CHANGELOG.md) | Release history |

---

## Support

If the demo or the project saved you time or inspired an idea, you can **buy me a coffee** — it fuels more free, open development like this.

<div align="center">

[![Buy me a coffee](https://img.shields.io/badge/Support_on_Ko--fi-FF5E5B?style=for-the-badge&logo=kofi&logoColor=white)](https://ko-fi.com/ai_dev_2024)

[**Support the project on Ko-fi →**](https://ko-fi.com/ai_dev_2024) · [**Open a support issue →**](https://github.com/ai-dev-2024/vehicle-selector-pro/issues/new?labels=support&template=blank_issue)

</div>

---

## License & contribution

This project is released under the [MIT License](LICENSE) © 2026 Vehicle Selector Pro contributors.

<div align="center">

[![MIT License](https://img.shields.io/badge/License-MIT-2ea44f?style=for-the-badge)](LICENSE)

[**Read the license →**](LICENSE) · [**Report an issue →**](https://github.com/ai-dev-2024/vehicle-selector-pro/issues/new?labels=bug&template=bug_report.md) · [**Request a feature →**](https://github.com/ai-dev-2024/vehicle-selector-pro/issues/new?labels=enhancement&template=feature_request.md)

</div>
