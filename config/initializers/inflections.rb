# Zeitwerk inflections: map filenames to constants whose default
# camelization would differ (e.g. graphql_error.rb -> GraphQLError).
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "graphql_error" => "GraphQLError",
    "graphql_client" => "GraphQLClient"
  )
end

# "billing" is a mass noun; Rails would otherwise pluralize the count noun and
# route the `resource :billing` to a BillingsController. Keep it singular so
# the controller is Admin::BillingController.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable %w[billing]
end
