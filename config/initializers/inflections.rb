# Zeitwerk inflections: map filenames to constants whose default
# camelization would differ (e.g. graphql_error.rb -> GraphQLError).
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    "graphql_error" => "GraphQLError",
    "graphql_client" => "GraphQLClient"
  )
end
