<div align="center">

<img src="docs/assets/banner.svg" alt="Vehicle Selector Pro" width="100%">

# Vehicle Selector Pro

### Fitment intelligence for Shopify automotive stores

[![GitHub](https://img.shields.io/badge/View_on_GitHub-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/ai-dev-2024/vehicle-selector-pro)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Rails](https://img.shields.io/badge/Rails-7.1-CC0000?style=flat-square&logo=rubyonrails&logoColor=white)](https://rubyonrails.org/)

</div>

---

Automotive merchants assign **Year / Make / Model / Trim / Engine** fitment data to their products. Customers filter the catalog with cascading dropdowns and see **"Guaranteed Exact Fit"** badges on product pages — powered by Shopify App Proxy, Product Metafields, and a Theme App Extension.

**[GitHub](https://github.com/ai-dev-2024/vehicle-selector-pro)** · **[Demo video](#demo)** · **[Setup guide](docs/SETUP.md)**

---

## Features

- **Cascading storefront widget** — Year, Make, Model, Trim, Engine dropdowns driven by HMAC-signed App Proxy queries
- **Product fitment badges** — Guaranteed Exact Fit / Does NOT Fit / Universal Fit on any product page
- **My Garage** — shoppers save multiple vehicles and switch between them across pages
- **Merchant admin** — fitment matrix, vehicle library, bulk CSV import, sync monitor, widget settings
- **Metafield sync** — fitment JSON synced to `$app.vehicle_fitment` via `metafieldsSet` in batches of 25
- **Webhook pipeline** — `products/*`, `app/uninstalled`, `shop/update` processed asynchronously via Sidekiq
- **Multi-tenant** — per-shop data isolation, encrypted tokens, HMAC-SHA256 verification on every request

---

## Screenshots

<div align="center">

**Merchant Admin Dashboard**

<img src="demo/autoplay/frames_live/01_dashboard.png" alt="Admin dashboard with 100% catalog coverage, 7 mapped products, and live sync status" width="100%">

**Vehicle Library (YMMTE Database)**

<img src="demo/autoplay/frames_live/02_vehicles.png" alt="Vehicle database with 33 vehicles across BMW, Chevrolet, Ford, and Jeep with cascading filters" width="100%">

**Product Fitment Matrix**

<img src="demo/autoplay/frames_live/03_fitment_rules.png" alt="Fitment rules matrix with 35 product-to-vehicle mappings, sync status, and edit controls" width="100%">

**Widget Configuration**

<img src="demo/autoplay/frames_live/05_settings.png" alt="Widget and Garage configuration with brand color, selector depth, and My Garage settings" width="100%">

**Bulk CSV Import**

<img src="demo/autoplay/frames_live/06_bulk_imports.png" alt="Bulk CSV fitment import with file upload and paste options" width="100%">

</div>

---

## Demo

<video src="demo/Vehicle_Selector_Pro_Demo.mp4" controls width="100%" poster="docs/assets/screenshot-hero.png">
  Your browser does not support the video tag — <a href="demo/Vehicle_Selector_Pro_Demo.mp4">download the .mp4</a>.
</video>

<sup>2-minute narrated walkthrough with natural AI voiceover (Edge TTS) · [script](docs/DEMO_SCRIPT.md)</sup>

---

## Quick start

### Installation

1. **Install the app** on your Shopify store:
   ```
   https://vehicle-selector-pro.fly.dev/login?shop=your-store.myshopify.com
   ```
2. **Approve permissions** when Shopify asks
3. **Access the app** from Shopify Admin → Apps → Vehicle Selector Pro

The app loads inside your Shopify admin — no separate login needed after installation.

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
