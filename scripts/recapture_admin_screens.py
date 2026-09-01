"""Re-capture the admin README screenshots from the live deployed app.

Storefront frames (04, 07, 08, 09) are left untouched: the layout fixes were
admin-only (command-center.css), and those frames carry specific shopper
states (selected vehicle, garage entries) that must be reproduced exactly.

Captures at 1440x900 @2x DPR = 2880x1800, matching the analytics/billing/OE
frames so the README gallery stays visually consistent.

Usage:
    python scripts/recapture_admin_screens.py
"""
import asyncio
from pathlib import Path

from playwright.async_api import async_playwright

BASE = "https://vehicle-selector-pro.fly.dev"
OUT_DIR = Path("demo/autoplay/frames_live")

SHOTS = [
    ("/demo/admin", "01_dashboard.png"),
    ("/demo/admin/vehicles", "02_vehicles.png"),
    ("/demo/admin/fitments", "03_fitment_rules.png"),
    ("/demo/admin/settings", "05_settings.png"),
    ("/demo/admin/imports", "06_bulk_imports.png"),
    ("/demo/admin/sync", "10_admin_sync.png"),
    ("/demo/admin/analytics", "11_admin_analytics.png"),
    ("/demo/admin/billing", "12_admin_billing.png"),
    ("/demo/admin/oe-numbers", "13_admin_oe_numbers.png"),
]

VIEWPORT = {"width": 1440, "height": 900}


async def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport=VIEWPORT, device_scale_factor=2)
        for path, name in SHOTS:
            try:
                await page.goto(f"{BASE}{path}", wait_until="networkidle", timeout=45_000)
            except Exception:
                await page.goto(f"{BASE}{path}", wait_until="load", timeout=45_000)
            await page.wait_for_timeout(1200)  # let fonts/charts/health check settle
            out = OUT_DIR / name
            await page.screenshot(path=str(out), full_page=False)
            print(f"saved {out}")
        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
