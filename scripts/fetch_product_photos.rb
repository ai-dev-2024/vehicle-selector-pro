#!/usr/bin/env ruby
# Fetches freely-licensed product photos for the demo catalog from Wikimedia
# Commons (CC BY-SA / CC BY / CC0 — attribution captured in photo_credits.json).
#
# Usage:
#   ruby scripts/fetch_product_photos.rb            # download missing files
#   ruby scripts/fetch_product_photos.rb --force    # re-download everything
#   ruby scripts/fetch_product_photos.rb --candidates <query terms...>
#                                                   # list ranked candidates to pick from
#
# Optional manual curation: scripts/photo_picks.json maps a target filename to
# an exact Commons File title, e.g. {"wiper-blades.jpg": "File:..."}.
# Picks beat search results and make the fetch deterministic. Attribution for
# every downloaded file is recorded in photo_credits.json regardless.

require "json"
require "net/http"
require "uri"
require "fileutils"

# Target filename => Commons search query
TARGETS = {
  "brake-pads.jpg" => "disc brake pads",
  "rotors-mustang.jpg" => "drilled brake disc",
  "shocks.jpg" => "shock absorber car",
  "leveling-kit.jpg" => "coil spring suspension car",
  "springs-civic.jpg" => "lowering springs car",
  "intake-mustang.jpg" => "cold air intake",
  "intake-ram.jpg" => "air intake filter car engine",
  "intake-civic.jpg" => "cone air filter",
  "intake-bronco.jpg" => "air filter car",
  "exhaust-tips.jpg" => "exhaust pipe car",
  "exhaust-ram.jpg" => "exhaust system truck",
  "light-bar.jpg" => "led light bar vehicle",
  "pod-kit-bronco.jpg" => "off-road led lights",
  "oil-kit.jpg" => "motor oil bottles",
  "wiper-blades.jpg" => "windshield wiper blade",
  "battery.jpg" => "car battery",
  "cabin-filter.jpg" => "cabin air filter",
  "air-filter.jpg" => "air filter element car",
  "floor-liners.jpg" => "car floor mat",
  "bed-mat.jpg" => "pickup truck bed",
  "trailer-hitch.jpg" => "trailer hitch",
  "roof-racks.jpg" => "roof rack car"
}.freeze

UA = "VehicleSelectorPro-demo/1.0 (contact: support@vehicleselectorpro.example)".freeze
OUT_DIR = File.expand_path("../public/demo-products", __dir__)
CREDITS_JSON = File.expand_path("photo_credits.json", __dir__)
PICKS_FILE = File.expand_path("photo_picks.json", __dir__)
PICKS = File.exist?(PICKS_FILE) ? JSON.parse(File.read(PICKS_FILE)) : {}

def api_search(query)
  uri = URI("https://commons.wikimedia.org/w/api.php")
  uri.query = URI.encode_www_form(
    action: "query", format: "json", formatversion: "2",
    generator: "search", gsrsearch: "filetype:bitmap #{query}",
    gsrnamespace: 6, gsrlimit: 10, prop: "imageinfo",
    iiprop: "url|size|mime|extmetadata", iiurlwidth: 1200
  )
  req = Net::HTTP::Get.new(uri, { "User-Agent" => UA })
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15,
                                            read_timeout: 30) { |http| http.request(req) }
  JSON.parse(res.body)
rescue StandardError => e
  warn "  ! search failed for #{query.inspect}: #{e.class}: #{e.message}"
  nil
end

def result_from_info(page, info)
  meta = info["extmetadata"] || {}
  {
    title: page["title"], page_url: info["descriptionurl"],
    download_url: info["thumburl"] || info["url"],
    artist: meta.dig("Artist", "value").to_s.gsub(/<[^>]+>/, "").strip[0, 80],
    license: meta.dig("LicenseShortName", "value") || "see source page"
  }
end

def info_of(page)
  info = page["imageinfo"]&.first
  return nil unless info
  return nil unless info["mime"] == "image/jpeg"
  return nil unless info["width"].to_i >= 700 && info["height"].to_i >= 500

  result_from_info(page, info)
end

def fetch_by_title(title)
  # Exact-file lookup: resolve a "File:<title>" to its imageinfo.
  uri = URI("https://commons.wikimedia.org/w/api.php")
  uri.query = URI.encode_www_form(
    action: "query", format: "json", formatversion: "2", titles: title,
    prop: "imageinfo", iiprop: "url|size|mime|extmetadata", iiurlwidth: 1200
  )
  req = Net::HTTP::Get.new(uri, { "User-Agent" => UA })
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15,
                                            read_timeout: 30) { |http| http.request(req) }
  page = JSON.parse(res.body)&.dig("query", "pages")&.first
  info = page && page["imageinfo"]&.first
  info ? result_from_info(page, info) : nil
end

def download(result, dest)
  uri = URI(result[:download_url])
  req = Net::HTTP::Get.new(uri, { "User-Agent" => UA })
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15,
                                            read_timeout: 60) { |http| http.request(req) }
  return nil unless res.code.to_i == 200 && res.body.bytesize > 10_000

  File.binwrite(dest, res.body)
  res.body.bytesize
end

# --candidates mode: list ranked results for a query, no downloads.
if ARGV[0] == "--candidates"
  query = ARGV[1..].join(" ")
  pages = api_search(query)&.dig("query", "pages") || []
  pages.sort_by { |p| p["index"].to_i }.each do |p|
    info = p["imageinfo"]&.first
    next unless info

    license = (info["extmetadata"] || {}).dig("LicenseShortName", "value") || "?"
    puts format("%<mime>-8s %<width>5dx%<height>-5d %<license>-12s %<title>s",
                mime: info["mime"].split("/").last, width: info["width"],
                height: info["height"], license: license, title: p["title"])
  end
  exit 0
end

credits = File.exist?(CREDITS_JSON) ? JSON.parse(File.read(CREDITS_JSON)) : {}
force = ARGV.include?("--force")

TARGETS.each do |filename, query|
  dest = File.join(OUT_DIR, filename)
  next if !force && File.exist?(dest) && File.size(dest) > 10_000

  puts "== #{filename}  (#{query})"
  if PICKS[filename]
    result = fetch_by_title(PICKS[filename])
    puts "   (manual pick: #{PICKS[filename]})"
  else
    pages = api_search(query)&.dig("query", "pages") || []
    result = pages.sort_by { |p| p["index"].to_i }
                  .lazy.map { |p| info_of(p) }.compact.first
  end
  unless result
    puts "   x no suitable result found"
    next
  end

  size = download(result, dest)
  if size
    credits[filename] = result
    puts "   ok  #{size / 1024} KB  <- #{result[:title]} (#{result[:license]})"
  else
    puts "   x download failed"
  end
end

File.write(CREDITS_JSON, JSON.pretty_generate(credits))
puts "== credits manifest: #{CREDITS_JSON}"
