import asyncio
import edge_tts
import os

ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, 'screen_recording')
AUDIO_DIR = os.path.join(OUTPUT, 'audio')

# Natural voice - Microsoft's neural voice (much better than Windows TTS)
VOICE = "en-US-GuyNeural"  # Professional male voice
# Alternatives: en-US-AriaNeural (female), en-US-ChristopherNeural (male)

# Scene-by-scene narration with timestamps
SCENES = [
    {
        "name": "01_intro",
        "text": "Vehicle Selector Pro. A production Shopify app for automotive and specialty parts merchants. Let me show you how it works.",
        "start": 0,
        "duration": 10
    },
    {
        "name": "02_dashboard",
        "text": "This is the merchant dashboard. At a glance, you can see seven mapped products, one hundred percent vehicle coverage, twenty-nine vehicle configurations, and zero items needing review. Everything is synced and up to date.",
        "start": 10,
        "duration": 25
    },
    {
        "name": "03_dashboard_scroll",
        "text": "Scrolling down, you see the recent fitment assignments. Each row shows the product, the compatible vehicle, the fitment type, and the sync status. All synced to Shopify product metafields.",
        "start": 35,
        "duration": 20
    },
    {
        "name": "04_vehicles",
        "text": "The vehicle library is the normalized cache behind every storefront dropdown. Thirty-three vehicles across BMW, Chevrolet, Ford, and Jeep. Each with year, make, model, trim, and engine data. You can filter by year, search by name, or export the full tree as JSON.",
        "start": 55,
        "duration": 30
    },
    {
        "name": "05_fitments",
        "text": "Fitment rules. Every product to vehicle mapping is a row in this matrix. You can see the product SKU, the compatible vehicle, the fitment type with installation notes, and the sync status. Edit or delete any rule instantly.",
        "start": 85,
        "duration": 30
    },
    {
        "name": "06_settings",
        "text": "Widget configuration. Merchants customize the storefront experience. Set your header title, brand color, subtitle, button labels. Toggle trim and engine selectors independently. Configure the My Garage feature for returning customers.",
        "start": 115,
        "duration": 25
    },
    {
        "name": "07_bulk",
        "text": "Bulk CSV import. Upload thousands of vehicle to product compatibility mappings at once. Download the template, fill in your data, and import. Or paste raw CSV text directly.",
        "start": 140,
        "duration": 20
    },
    {
        "name": "08_closing",
        "text": "And that's Vehicle Selector Pro. Production ready, deployed on Fly.io, open source on GitHub. Try it on your store today.",
        "start": 160,
        "duration": 15
    }
]

async def generate_voiceover():
    os.makedirs(AUDIO_DIR, exist_ok=True)

    for scene in SCENES:
        output_file = os.path.join(AUDIO_DIR, f"{scene['name']}.mp3")
        print(f"Generating: {scene['name']}...")

        communicate = edge_tts.Communicate(scene['text'], VOICE, rate="+5%")
        await communicate.save(output_file)
        print(f"  Saved: {output_file}")

    # Generate full continuous narration
    full_text = " ".join([s['text'] for s in SCENES])
    full_path = os.path.join(AUDIO_DIR, "full_narration.mp3")
    print(f"\nGenerating full narration...")
    communicate = edge_tts.Communicate(full_text, VOICE, rate="+5%")
    await communicate.save(full_path)
    print(f"Saved full narration: {full_path}")

    print(f"\nDone! {len(SCENES)} scene audio files + full narration in {AUDIO_DIR}")

if __name__ == "__main__":
    asyncio.run(generate_voiceover())
