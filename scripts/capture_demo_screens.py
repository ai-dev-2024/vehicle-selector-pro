"""Capture live screenshots of the read-only demo admin pages.

Captures the analytics, billing, and OE-number pages from the deployed app
and saves them into demo/autoplay/frames_live/ so the README can embed them
alongside the existing admin screenshots.

Usage:
    python scripts/capture_demo_screens.py
"""

import asyncio
from pathlib import Path

from playwright.async_api import async_playwright

BASE = "https://vehicle-selector-pro.fly.dev"
OUT_DIR = Path("demo/autoplay/frames_live")

SHOTS = [
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
            url = f"{BASE}{path}"
            try:
                await page.goto(url, wait_until="networkidle", timeout=45_000)
            except Exception:
                # networkidle can be flaky with long-polling; fall back to load.
                await page.goto(url, wait_until="load", timeout=45_000)
            await page.wait_for_timeout(1200)  # let fonts/charts settle
            out = OUT_DIR / name
            await page.screenshot(path=str(out), full_page=False)
            print(f"saved {out}")
        await browser.close()


if __name__ == "__main__":
    asyncio.run(main())
