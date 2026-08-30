<div align="center">

<img src="docs/assets/banner.svg" alt="Vehicle Selector Pro" width="100%">

# Vehicle Selector Pro

### Fitment intelligence for Shopify automotive stores

[![Live Demo](https://img.shields.io/badge/Live_Storefront_Demo-008060?style=flat-square&logo=shopify&logoColor=white)](https://vehicle-selector-pro.fly.dev/demo)
[![Admin Preview](https://img.shields.io/badge/Live_Admin_Preview-1f6feb?style=flat-square)](https://vehicle-selector-pro.fly.dev/demo/admin)
[![GitHub](https://img.shields.io/badge/View_on_GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/ai-dev-2024/vehicle-selector-pro)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Rails](https://img.shields.io/badge/Rails-7.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)

</div>

---

Automotive merchants assign **Year / Make / Model / Trim / Engine** fitment data to their products. Customers filter the catalog with cascading dropdowns and see **"Guaranteed Exact Fit"** badges on product pages — powered by Shopify App Proxy, Product Metafields, and a Theme App Extension.

**[Live storefront demo](https://vehicle-selector-pro.fly.dev/demo)** · **[Live admin preview](https://vehicle-selector-pro.fly.dev/demo/admin)** · **[Demo video](#demo)** · **[Setup guide](docs/SETUP.md)** · **[Architecture](#architecture)**

> **Installing on your own store** — this is a custom (unlisted) app, so Shopify requires installation through the Partners distribution link. Open an issue or request access and we will generate an install link for your store. The live demo above needs no installation.

---

## Demo

<div align="center">

<video src="demo/Vehicle_Selector_Pro_Demo_v3.mp4" controls width="100%" poster="docs/assets/screenshot-hero.png">
  Your browser does not support the video tag — <a href="demo/Vehicle_Selector_Pro_Demo_v3.mp4">download the .mp4</a>.
</video>

**[▶ Watch the 2.5-minute walkthrough](demo/Vehicle_Selector_Pro_Demo_v3.mp4)** — real screen recording of the working app with studio AI voiceover and background score · [script](docs/DEMO_SCRIPT.md) · [interactive walkthrough](demo/index.html)

</div>

---

## Features

- **Cascading storefront widget** — Year, Make, Model, Trim, Engine dropdowns driven by HMAC-signed App Proxy queries
- **Product fitment badges** — Guaranteed Exact Fit / Does NOT Fit / Universal Fit on any product page
- **My Garage** — shoppers save multiple vehicles and switch between them across pages
- **Merchant admin** — fitment matrix, vehicle library, bulk CSV import, sync monitor, widget settings
- **Metafield sync** — fitment JSON synced to `custom.vehicle_fitment` via `metafieldsSet` in batches of 25
- **Webhook pipeline** — `products/*`, `app/uninstalled`, `shop/update` processed asynchronously via Sidekiq
- **Multi-tenant** — per-shop data isolation, encrypted tokens, HMAC-SHA256 verification on every request

---

## Screenshots

### Storefront (live demo)

<div align="center">

**Home — cascading Year / Make / Model / Trim / Engine widget with shop-by-category and featured parts**

<img src="demo/autoplay/frames_live/04_storefront_home.png" alt="Storefront home with hero, cascading vehicle selector widget, category tiles, and featured product cards" width="100%">

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

<img src="demo/autoplay/frames_live/02_vehicles.png" alt="Vehicle library with 33 Year/Make/Model/Trim/Engine configurations across BMW, Chevrolet, Ford, and Jeep" width="100%">

**Product fitment matrix — every product-to-vehicle mapping with sync status**

<img src="demo/autoplay/frames_live/03_fitment_rules.png" alt="Fitment matrix with 87 product-to-vehicle mappings, universal fits, sync badges, and edit controls" width="100%">

**Widget & Garage configuration**

<img src="demo/autoplay/frames_live/05_settings.png" alt="Widget settings with brand color, selector depth, button labels, and My Garage options" width="100%">

**Bulk CSV import**

<img src="demo/autoplay/frames_live/06_bulk_imports.png" alt="Bulk fitment CSV import with file upload and paste options" width="100%">

**Metafield sync monitor**

<img src="demo/autoplay/frames_live/10_admin_sync.png" alt="Sync monitor showing background metafield synchronization progress" width="100%">

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
bundle exec rails db:prepare db:seed
bundle exec rails server
```

Then open `http://localhost:3000` for the admin dashboard, or `http://localhost:3000/storefront_preview` to see the Theme App Extension widget against live data.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Ruby on Rails 7.1 |
| Database | PostgreSQL (production) / SQLite (dev) |
| Background jobs | Sidekiq + Redis |
| Shopify integration | Theme App Extension (OS 2.0), App Proxy, GraphQL Admin API (`metafieldsSet`) |
| Security | HMAC-SHA256 verification, Rack::Attack throttling, ActiveRecord Encryption |
| Hosting | Fly.io (Puma + Sidekiq + Postgres + private Redis) |

---

## Documentation

| | |
|---|---|
| [Setup guide](docs/SETUP.md) | Local development environment |
| [Deployment](docs/DEPLOYMENT.md) | Fly.io runbook with provisioning commands |
| [API reference](docs/API.md) | App Proxy endpoints and webhook topics |
| [Architecture](docs/ARCHITECTURE.md) | System diagrams and data model |
| [Demo script](docs/DEMO_SCRIPT.md) | Voiceover narration for the walkthrough video |
| [Changelog](CHANGELOG.md) | Release history |

---

## License

[MIT](LICENSE) © 2026 Vehicle Selector Pro contributors.

<div align="center">

[Report an issue](https://github.com/ai-dev-2024/vehicle-selector-pro/issues) · [Request a feature](https://github.com/ai-dev-2024/vehicle-selector-pro/issues/new)

</div>
