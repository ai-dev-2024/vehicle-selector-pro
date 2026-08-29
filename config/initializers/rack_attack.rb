class Rack::Attack
  # Throttle App Proxy: 60 req/min per IP
  throttle('vsp/app_proxy', limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/apps/vehicle-selector')
  end

  # Throttle webhooks: 300 req/min per IP (Shopify bursts)
  throttle('vsp/webhooks', limit: 300, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/webhooks')
  end

  self.throttled_responder = lambda do |env|
    [429, { 'Content-Type' => 'application/json' }, [{ error: 'Rate limit exceeded, retry later' }.to_json]]
  end
end
