module Shopify
  # Integration with the Shopify Billing API. Uses the same GraphQL client as
  # the rest of the app to create recurring app subscriptions (which surface
  # the merchant's standard Shopify native checkout) and to check which plan a
  # shop is actively subscribed to.
  #
  # Two entry points a controller needs:
  #   - `create_subscription(plan_key)` returns the native confirmationUrl the
  #     merchant is redirected to.
  #   - `active_plan_key` (and `active_chart_names`) lets the app sync its
  #     shops.billing_plan column to whatever Shopify reports.
  class BillingService
    RECURRING_INTERVAL = "EVERY_30_DAYS".freeze
    CURRENCY_CODE = "USD".freeze

    CREATE_SUBSCRIPTION_MUTATION = <<~GRAPHQL.freeze
      mutation AppSubscriptionCreate(
        $name: String!
        $returnUrl: URL!
        $lineItems: [AppSubscriptionLineItemInput!]!
        $trialDays: Int
        $test: Boolean
      ) {
        appSubscriptionCreate(
          name: $name
          returnUrl: $returnUrl
          lineItems: $lineItems
          trialDays: $trialDays
          test: $test
        ) {
          appSubscription { id name }
          confirmationUrl
          userErrors { field message code }
        }
      }
    GRAPHQL

    ACTIVE_SUBSCRIPTIONS_QUERY = <<~GRAPHQL.freeze
      query ActiveSubscriptions {
        currentAppInstallation {
          activeSubscriptions {
            id
            name
            test
          }
        }
      }
    GRAPHQL

    attr_reader :shop

    def initialize(shop)
      @shop = shop.is_a?(Shop) ? shop : Shop.find_by!(shopify_domain: shop.to_s)
      @client = GraphQLClient.new(@shop)
    end

    # Creates a recurring subscription for the given plan key and returns the
    # native Shopify confirmation URL, or nil if the shop already has one of
    # the paid charts active.
    def create_subscription(plan_key, return_host: default_return_host, test: billing_test?)
      plan = BillingPlan.find(plan_key)
      return nil unless plan

      if (names = active_chart_names).any?
        # Already subscribed to a billable plan — don't stack another chart.
        Rails.logger.info("[BillingService] #{shop.shopify_domain} already active on: #{names.join(', ')}")
        return nil
      end

      data = @client.mutate(CREATE_SUBSCRIPTION_MUTATION, {
                              name: plan.chart_name,
                              returnUrl: "#{return_host}/admin/billing/return",
                              lineItems: [
                                {
                                  plan: {
                                    appRecurringPricingDetails: {
                                      interval: RECURRING_INTERVAL,
                                      price: {
                                        amount: plan.price.to_s,
                                        currencyCode: CURRENCY_CODE
                                      }
                                    }
                                  }
                                }
                              ],
                              trialDays: plan.trial_days,
                              test: test
                            })

      result = data["appSubscriptionCreate"]
      user_errors = result["userErrors"] || []
      raise GraphQLError, "Billing subscription error: #{user_errors.pluck('message').join('; ')}" unless user_errors.empty?

      result["confirmationUrl"]
    end

    # The billing charts the shop currently has active (names of non-test
    # subscriptions in production), used to reconcile shops.billing_plan.
    def active_chart_names
      data = @client.query(ACTIVE_SUBSCRIPTIONS_QUERY)
      subs = data.dig("currentAppInstallation", "activeSubscriptions") || []
      subs.filter_map do |sub|
        next if !Rails.env.production? && sub["test"] == false
        next if Rails.env.production? && sub["test"]

        sub["name"]
      end
    end

    # Maps the shop's active charts back to a BillingPlan key (first match),
    # returning nil if none of the recuring charts match a known plan.
    def active_plan_key
      names = active_chart_names
      return nil if names.empty?

      BillingPlan.all.find { |p| names.include?(p.chart_name) }&.key
    end

    private

    def default_return_host
      ENV["HOST"] || "http://localhost:3000"
    end

    def billing_test?
      Rails.env.production? ? ENV["SHOPIFY_BILLING_TEST"] == "true" : true
    end
  end
end
