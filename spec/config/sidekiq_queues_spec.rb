require "rails_helper"

# Sidekiq only polls the queues listed in config/sidekiq.yml. A job whose
# queue_as is missing from that list is enqueued and never worked, which is
# how every Metafields job once sat unprocessed on the `sync` queue.
RSpec.describe "Sidekiq queue configuration" do
  it "works every queue a job enqueues to" do
    Rails.application.eager_load!
    config = YAML.safe_load_file(Rails.root.join("config/sidekiq.yml"), permitted_classes: [Symbol])
    configured = config.fetch(:queues).map { |name, _weight| name.to_s }
    used = ApplicationJob.descendants.map { |job| job.queue_name.to_s }.uniq

    expect(used - configured).to be_empty
  end
end
