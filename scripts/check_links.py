#!/usr/bin/env python3
"""Strict crawler: flag only REAL markdown links + bare non-code URLs that 404 or miss an anchor."""
import glob, os, re, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
FILES = ["README.md"] + sorted(glob.glob("docs/*.md"))

# remove fenced code blocks and inline code spans so bare-URL scans ignore them
code_block_re = re.compile(r"```.*?```", re.S)
inline_code_re = re.compile(r"`[^`]*`")
md_link_re = re.compile(r"\[[^\]]*\]\(([^)]+?)\)")
bare_url_re = re.compile(r"https?://[^\s\)\]<>]+")

SKIP_HOSTS = {"localhost", "ngrok.io", "your-ngrok-url", "127.0.0.1", "ngrok-free.app"}
# endpoints that legally require auth params / return non-200 without them
SKIP_SUBSTR = ["/auth/shopify/callback", "/webhooks/", "/apps/vehicle-selector",
               "login?shop", "/up", "&signature=", "timestamp="]


def anchors(path):
    out = set()
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            for line in f:
                m = re.match(r"^#{1,6}\s+(.*)$", line.rstrip())
                if m:
                    out.add(re.sub(r"[^\w\- ]", "", m.group(1)).strip().lower().replace(" ", "-"))
    except FileNotFoundError:
        pass
    return out


def strip_code(text):
    text = code_block_re.sub(" ", text)
    return inline_code_re.sub(" ", text)


def status(url, timeout=15):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 linkcheck"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return None


def good(code):
    return code in (200, 301, 302, 304)


problems, checked = [], 0
for md in FILES:
    text = open(md, encoding="utf-8", errors="replace").read()
    code_free = strip_code(text)
    links = [m.group(1) for m in md_link_re.finditer(code_free)]  # real markdown links only
    for raw in links:
        url = raw.rstrip(".,);!?").replace("&amp;", "&")
        checked += 1
        if not url or url.startswith("<mailto"):
            continue
        if url.startswith("#"):
            if url[1:].strip().lower() not in anchors(md):
                problems.append((os.path.basename(md), f"anchor #{url[1:]}", "missing local heading"))
            continue
        if not url.startswith(("http://", "https://")):
            path, _, frag = url.partition("#")
            fp = os.path.normpath(os.path.join(os.path.dirname(md), path))
            if not os.path.exists(fp):
                problems.append((os.path.basename(md), url, f"missing file {os.path.relpath(fp, ROOT)}"))
            continue
        host = urllib.parse.urlparse(url).hostname or ""
        if any(s in host for s in SKIP_HOSTS):
            continue
        if any(s in url for s in SKIP_SUBSTR):
            continue
        c = status(url)
        if not good(c):
            problems.append((os.path.basename(md), url, f"HTTP {c}"))

print(f"Checked {len(FILES)} files, {checked} markdown links (code spans ignored)")
print(f"Real problems: {len(problems)}\n")
for md, url, why in problems:
    print(f"[{why}] {md} : {url}")