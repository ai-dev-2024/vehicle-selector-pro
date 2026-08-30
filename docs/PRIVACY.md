# Privacy Policy — Vehicle Selector Pro

**Effective date:** August 31, 2026

Vehicle Selector Pro ("the App") is a Shopify app operated by the Vehicle Selector Pro team. This policy explains what data the App processes, why, how long it is kept, and how to exercise your rights.

## 1. Who this policy covers

- **Merchants** who install the App on their Shopify store.
- **Shoppers** who use the vehicle selector widget on a merchant's storefront.

The App is installed via the Shopify platform, so merchant contact and billing are handled by Shopify under [Shopify's own privacy policy](https://www.shopify.com/legal/privacy).

## 2. Data the App processes

### Merchant (store) data

| Data | Purpose | Stored where |
|---|---|---|
| Shop domain, shop name, contact email, currency, timezone | App operation, support, sync status display | App database (PostgreSQL) |
| Shopify access token (OAuth) | Calling the Shopify Admin API on the merchant's behalf (product metafield sync) | App database, **encrypted at rest** (Rails ActiveRecord Encryption); revoked and overwritten on app uninstall |
| Products the merchant maps to vehicles (IDs, titles, handles, SKUs) | Fitment matrix, sync, storefront badges | App database |
| Vehicle fitment records (Year/Make/Model/Trim/Engine ↔ product mappings) | Core app functionality | App database; also mirrored to product metafields on the merchant's own store |

### Shopper (end-customer) data

**The App stores no customer PII.** Shopper vehicle selections ("My Garage") are stored **only in the shopper's own browser localStorage** and are never transmitted to the App. App Proxy requests carry vehicle filter parameters, not identity data; the App cannot link a vehicle selection to a person.

No shopper names, emails, addresses, or order data are accessed or stored by the App.

## 3. GDPR mandatory webhooks

The App implements the three Shopify-mandatory compliance webhooks:

- **`customers/data_request`** — responds confirming there is no customer PII to export; vehicle selections live in the shopper's browser.
- **`customers/redact`** — responds confirming there is no customer PII to erase.
- **`shop/redact`** — erases all shop-scoped data (fitments, vehicles, sync logs, settings) 48 hours after app uninstall, per Shopify policy, by destroying the shop record and dependent rows.

## 4. Data retention

- Shop data is retained while the app is installed. After uninstall, the shop is deactivated immediately and its data is erased via `shop/redact` (Shopify delivers this webhook 48 hours after uninstall).
- Encrypted access tokens are invalidated on uninstall.
- No backup or copy of shop data is kept outside the App database.

## 5. Third parties

The App runs on Fly.io (application hosting, EU/US regions) and uses the hosting platform's managed Redis and PostgreSQL. Data is additionally processed by Shopify under Shopify's data processing terms. The App does not sell, share, or transfer data to any other third party, and does not transfer data outside the hosting regions.

## 6. Security

- OAuth 2.0 with least-privilege scopes (`read_products`, `write_products`, `read_product_listings`, `read_customers`, `write_customers`).
- HMAC-SHA256 signature verification on every App Proxy and webhook request; admin UI requires a verified Shopify session.
- Access tokens encrypted at rest; secrets held in environment variables / Fly secrets.
- Rate limiting via Rack::Attack; all admin data queries shop-scoped.

## 7. Your rights

Merchants can request export or deletion of their store's data at any time by uninstalling the app (automatic erasure via `shop/redact`) or by contacting us. Shoppers should contact the merchant whose store they visited; the App holds no shopper data to act on.

**Contact:** open an issue at the project repository, or email the address listed on the app's Partners Dashboard listing.

## 8. Changes

Material changes to this policy will be reflected in the app's repository and listing before they take effect.
