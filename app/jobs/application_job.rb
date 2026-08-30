class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to end up in the deadset after exhausting retries;
  # Sidekiq's deadset keeps them inspectable instead of losing them silently.
  discard_on ActiveJob::DeserializationError

  # Cap retries so a permanently failing webhook doesn't retry forever —
  # Sidekiq will move exhausted jobs to the deadset (retry: false would
  # silently drop them, losing the payload).
  retry_on StandardError, wait: :exponential, jitter: 0.15, attempts: 5
end
