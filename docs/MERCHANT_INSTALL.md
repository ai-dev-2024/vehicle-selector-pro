# Merchant Installation & Handoff

This project has two separate things:

1. **The deployed app** — Rails, database, Sidekiq and the Shopify Partner app credentials. The developer/operator owns and deploys this.
2. **The merchant's Shopify store** — the client's store, products, theme and Shopify login. The merchant owns this and signs in directly.

A client should never receive the app secret, Fly token, database credentials or another person's Shopify password.

## Recommended client flow

### 1. Deploy the app once

The operator provisions Fly.io, configures runtime secrets, and deploys the Rails app. See [`DEPLOYMENT.md`](DEPLOYMENT.md).

Runtime secrets include:

- `SHOPIFY_API_KEY` and `SHOPIFY_API_SECRET` from the Shopify Partners app
- `DATABASE_URL` for the production database
- `REDIS_URL` for Sidekiq/cache
- `HOST=https://vehicle-selector-pro.fly.dev`
- `SECRET_KEY_BASE` and Active Record Encryption keys

Store these in Fly secrets or the deployment provider's secret manager. Do not commit them to GitHub.

### 2. Configure Shopify Partner settings

In the Shopify Partners Dashboard, configure:

- App URL: `https://vehicle-selector-pro.fly.dev`
- OAuth callback: `https://vehicle-selector-pro.fly.dev/auth/shopify/callback`
- App Proxy: `apps/vehicle-selector` mapped to the deployed app
- Webhooks from `shopify.app.toml`
- Customer-privacy webhooks in the Partners Dashboard
- Distribution mode: development, custom/unlisted, or public listing as appropriate

Run `shopify app deploy --allow-updates` after reviewing the extension changes. This is separate from `flyctl deploy`: Fly deploys the Rails server, while Shopify CLI publishes the Theme App Extension and Partner configuration.

### 3. Give the merchant the install URL

For a store domain such as `client-store.myshopify.com`, send:

```text
https://vehicle-selector-pro.fly.dev/login?shop=client-store.myshopify.com
```

The merchant opens the URL, signs in to Shopify themselves, reviews the requested permissions, and clicks Install/Approve. No Shopify password needs to be sent to the developer.

For a public Shopify app, the merchant can install from the App Store listing instead. For a custom app, use the Partner distribution/install link or the direct OAuth URL above.

### 4. Finish store setup

After OAuth succeeds:

1. Open the embedded Vehicle Selector Pro admin.
2. Confirm the store domain and shop-scoped records.
3. Create the `custom.vehicle_fitment` product metafield definition in Shopify admin if the app setup indicates it is missing; use JSON type and public storefront read access.
4. Import the merchant's real catalog/fitments through **Admin → Bulk CSV import**, or enter fitments in the matrix.
5. Run metafield sync and verify a product's `custom.vehicle_fitment` value in Shopify admin.
6. Add the Theme App Extension blocks to the merchant's theme in **Online Store → Themes → Customize**.
7. Preview the theme, select a vehicle, verify filtered products and the fitment badge, then publish the theme.

## What the client receives

- The storefront/theme experience and Shopify admin app access
- The install/distribution URL
- A CSV template and fitment import instructions
- The deployed app URL and support contact
- A short handoff guide, not infrastructure secrets

## What remains operator-only

- Shopify Partner app client secret
- Fly.io access token and account
- Production database and Redis credentials
- Active Record encryption keys
- GitHub repository write access unless intentionally granted

## Troubleshooting

- **OAuth says redirect URL is invalid:** make sure `HOST`, `application_url` and the Partner callback URL all use the same deployed HTTPS hostname.
- **App installs but storefront widget is missing:** publish the Theme App Extension and add its blocks to the active theme.
- **Products do not filter:** confirm the merchant imported fitments for the same shop and that the App Proxy points to the deployed hostname.
- **Fitment badge is blank:** select a vehicle first, then verify the product has a matching fitment or is marked universal.
