require "rails_helper"

# A route whose controller or action does not exist only fails when someone
# requests it. That is how /api/v1/storefront/* sat broken: `to:` inside a
# namespace resolves relative to the namespace, so it pointed at controllers
# that were never defined.
RSpec.describe "Application routes" do
  it "all point at an existing controller action" do
    Rails.application.eager_load!

    broken = Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]
      next if controller.blank? || action.blank?

      klass = "#{controller.camelize}Controller".safe_constantize
      "#{route.path.spec} -> #{controller}##{action}" unless klass&.action_methods&.include?(action.to_s)
    end

    expect(broken).to be_empty
  end
end
