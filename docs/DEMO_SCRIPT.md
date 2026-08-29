# Vehicle Selector Pro — 2.5 minute walkthrough script

Use this as a live voiceover, or click **Play 2.5-min walkthrough** on the demo. The in-browser demo speaks these lines via the Web Speech API and can record the tab with **Record & download video**.

| Time | Scene | Line |
|------|--------|------|
| 0:00 | Overview | Welcome to Vehicle Selector Pro — a production Rails 7 Shopify app with a Theme App Extension. |
| 0:12 | Metrics | The command center shows catalog coverage, mapped products, and rules that still need review. |
| 0:24 | Selector | On the storefront, Year cascades into Make, Model, and Trim through the HMAC-signed App Proxy. |
| 0:36 | YMM | Selecting Ford, then F-150, then Lariat — the same tree the merchant maintains in the vehicle library. |
| 0:50 | Search | Search compatible parts. Collection filters use native Shopify metafield tokens. Responses stay under fifteen milliseconds from cache. |
| 1:04 | Garage | My Garage stores household vehicles in localStorage so shoppers can switch without starting over. |
| 1:16 | PDP fit | On the product page, a guaranteed exact-fit badge confirms the Apex intake for this F-150. |
| 1:30 | PDP miss | Incompatible parts fail loudly. This Mustang exhaust does not fit the F-150 — reducing returns. |
| 1:42 | Universal | Universal accessories still sell. LED pods show a universal fitment guarantee. |
| 1:52 | Rules | Merchants manage the fitment matrix here. Live rules ship. Incomplete trim data stays in review. |
| 2:04 | Library | The vehicle library is the normalized YMMTE cache behind every cascading dropdown. |
| 2:14 | Sync | Sidekiq batch-syncs to Shopify GraphQL using metafieldsSet. Webhooks keep the cache honest. |
| 2:24 | Security | HMAC-SHA256 on every App Proxy request. Thirty-five assertions passing. Production ready. |
| 2:29 | Close | Demonstration complete. Full source is on GitHub at ai-dev-2024 / vehicle-selector-pro. |
