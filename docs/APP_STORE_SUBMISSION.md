# App Store Submission Guide — Vehicle Selector Pro

Everything needed to submit this app to the Shopify App Store, in order. Items marked **[Dashboard]** happen in the Shopify Partners Dashboard, **[Repo]** are files in this repository, **[Live]** are URL entries pointing at the deployed app.

## 0. Pre-flight — what must already be true

- [x] All spec requirements implemented and verified (see `REQUIREMENTS-VERIFICATION.md`)
- [x] GDPR webhooks implemented (`/webhooks/customers_data_request`, `/webhooks/customers_redact`, `/webhooks/shop_redact`)
- [x] Privacy policy hosted or linkable (`docs/PRIVACY.md` — must be publicly reachable at submission; see step 3)
- [x] App deployed and healthy (Fly.io, `https://vehicle-selector-pro.fly.dev`)
- [x] Session-based admin auth (App Bridge / OAuth session required for every admin route)
- [x] Billing via Shopify Billing API (`appSubscriptionCreate`, native checkout; test-mode gated — see step 5)
- [ ] Theme App Extension released via `shopify app deploy` (2 blocks + snippet) — run this against the target Shopify Partner app before submitting

## 1. [Dashboard] App information

- **App name:** Vehicle Selector Pro
- **App URL:** `https://vehicle-selector-pro.fly.dev`
- **Allowed redirection URL:** `https://vehicle-selector-pro.fly.dev/auth/shopify/callback`
- **App proxy:** subpath `apps/vehicle-selector` → `https://vehicle-selector-pro.fly.dev` (already configured and verified live)
- **Embedded app:** enabled (App Bridge)

## 2. [Dashboard] Mandatory customer-privacy webhooks

Under **App setup → Event subscriptions → Customer privacy**, register:

- `customers/data_request` → `https://vehicle-selector-pro.fly.dev/webhooks/customers_data_request`
- `customers/redact` → `https://vehicle-selector-pro.fly.dev/webhooks/customers_redact`
- `shop/redact` → `https://vehicle-selector-pro.fly.dev/webhooks/shop_redact`

These three cannot be registered via the API; the Rails endpoints already exist and return 200.

## 3. [Live] Hosting the privacy policy

Shopify requires a **publicly reachable URL**. The repo file is not enough. Fastest path:

```
flyctl deploy   # after adding a /privacy route, or:
```

- Recommended: add a `get "privacy", to: "storefront_preview#privacy"` route rendering `docs/PRIVACY.md` as HTML, or
- publish the markdown to GitHub Pages / Notion and use that URL.

**This is the one remaining build item — see below.** The submission guide, listing copy, and review notes are ready; only the hosted-URL step is pending.

## 4. [Dashboard] Listing content (copy-paste ready)

**Tagline (≤60 chars):**
> Fitment intelligence for Shopify automotive stores

**Description:**

> **Stop guessing. Start fitting.**
>
> Vehicle Selector Pro lets automotive merchants attach Year / Make / Model / Trim / Engine fitment data to any product — and gives shoppers a cascading vehicle filter right on the storefront.
>
> - **Cascading vehicle widget** — shoppers pick Year → Make → Model → Trim → Engine and instantly see only the parts that fit their vehicle
> - **"Guaranteed Exact Fit" badges** — product pages show fit, no-fit, or universal-fit status, cutting wrong-part returns
> - **My Garage** — shoppers save multiple vehicles and switch between them on any page
> - **OE part-number search** — shoppers find parts by the factory OE number printed on the part they already own
> - **Fitment analytics** — see daily selector usage, fit rate, and which vehicle makes shoppers search most
> - **Bulk CSV import** — load thousands of fitment rows in minutes; a sample template is built in
> - **Automatic sync** — fitment data is written to product metafields via the Shopify GraphQL Admin API and kept current through product webhooks
> - **Multi-store ready** — every store's catalog and vehicles are isolated and encrypted
>
> Built natively on Shopify: Theme App Extension blocks (no ScriptTag), App Proxy filtering, Polaris-styled admin, Sidekiq-backed webhooks. Works with any OS 2.0 theme.

**Categories:** Automotive & Vehicles; Store design

**Keywords:** vehicle fitment, year make model, auto parts, garage, fitment filter, OE number

**Pricing:** Free to install; Pro $9.99/mo and Pro Plus $29.99/mo with 14-day free trials (Shopify Billing API, native checkout). The app is fully functional on the free tier (500 fitments).

**Screenshots (already produced, in `demo/autoplay/frames_live/`):** dashboard with coverage stats, vehicle library, fitment matrix, analytics dashboard, plans & billing, widget settings, bulk import, storefront widget + garage + PDP badges.

**Demo video:** [Inline narrated walkthroughs on the GitHub repository](https://github.com/ai-dev-2024/vehicle-selector-pro#demo) · [fullscreen GitHub Pages video gallery](https://ai-dev-2024.github.io/vehicle-selector-pro/demo/videos.html). The original MP4 is also included at `demo/Vehicle_Selector_Pro_Demo_v3.mp4`.

## 5. [Dashboard] Review notes (paste into "Notes for reviewers")

```
Demo store: https://vehicle-selector-pro.myshopify.com
Staff account for review: (create one before submitting)

What this app does:
1. Admin (embedded): open the app from the admin → dashboard shows catalog
   coverage; Product fitments has the fitment matrix; Sync triggers metafield
   writes; Bulk imports accepts the sample CSV in db/sample-data/.
2. Analytics: the Analytics page shows storefront fitment checks, fit rate,
   and checks-by-make from daily aggregates (populated as the storefront
   selector is used).
3. Plans & billing: the Plans page shows the Free/Pro/Pro Plus tiers.
   Subscriptions are created through the Shopify Billing API with native
   checkout. Billing runs in TEST MODE for this review install — no real
   charges occur. The free tier is fully functional; paid tiers only raise
   the bulk-import fitment ceiling.
4. Storefront: the theme has the app's two blocks added (vehicle selector
   filter + product fitment badge). Pick Year=2024 Ford F-150 Lariat to see
   filtered results; a mapped product page shows the fit badge; the Garage
   saves the vehicle. The OE-number search accepts a factory part number.
5. App Proxy endpoints are HMAC-verified (tampered signatures → 401).
6. GDPR webhooks are registered and return 200; shop/redact erases all
   shop-scoped data.

No paid plan is required during review; the app is fully functional in
demo mode on the free tier.
```

## 6. [Dashboard] Submission checklist

- [ ] Privacy policy URL set (step 3)
- [ ] Listing copy + screenshots + video uploaded (include analytics and billing screenshots)
- [ ] Pricing entered in the Dashboard matches `BillingPlan` (Free / Pro $9.99 / Pro Plus $29.99, 14-day trials)
- [ ] Billing test mode confirmed for the review install (`SHOPIFY_BILLING_TEST=true` on the deployed app, or test mode set in the Partner Dashboard) — reviewers must never be charged
- [ ] Mandatory GDPR webhooks registered (step 2)
- [ ] App URL / redirect URLs correct (step 1)
- [ ] Review staff account created on the demo store
- [ ] `shopify app deploy` run so the released extension version matches the repo (required before submission)
- [ ] Submit for review

## 7. After approval

- [ ] Set distribution to "Public listing"
- [ ] Switch billing to live mode (`SHOPIFY_BILLING_TEST=false`) and verify a real subscription activates end-to-end
- [ ] Monitor Sidekiq deadset + `MetafieldSyncLog` failures for the first week
- [ ] Keep `REQUIREMENTS-VERIFICATION.md` updated when scopes or endpoints change
