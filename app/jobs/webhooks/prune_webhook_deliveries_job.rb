module Webhooks
  # Housekeeping: drops webhook dedup rows older than the retention window.
  # Triggered opportunistically (low probability inside the dedup path) so no
  # external cron/scheduler is required on Fly.
  class PruneWebhookDeliveriesJob < ApplicationJob
    queue_as :low_priority

    def perform
      pruned = WebhookDelivery.prune!
      Rails.logger.info("[Webhooks::PruneWebhookDeliveriesJob] Pruned #{pruned} stale dedup rows")
    end
  end
end
