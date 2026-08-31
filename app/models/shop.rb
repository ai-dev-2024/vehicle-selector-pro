class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorage

  encrypts :shopify_token, deterministic: false if respond_to?(:encrypts)

  # Associations
  has_many :vehicle_product_fitments, dependent: :destroy
  has_many :oe_numbers, dependent: :destroy
  has_many :metafield_sync_logs, dependent: :destroy
  has_one :app_setting, dependent: :destroy
  has_many :vehicles, -> { distinct }, through: :vehicle_product_fitments

  # Validations
  validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
  validates :shopify_token, presence: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Callbacks
  after_create :initialize_settings

  def api_version
    ShopifyApp.configuration.api_version
  end

  def mark_as_uninstalled!
    update!(
      active: false,
      uninstalled_at: Time.current,
      shopify_token: "revoked_#{SecureRandom.hex(8)}"
    )
  end

  def reinstall!(token, scopes)
    update!(
      shopify_token: token,
      access_scopes: scopes,
      active: true,
      uninstalled_at: nil
    )
  end

  # shopify_app stores every authenticated session through this hook (via
  # SessionRepository.store_shop_session -> Shop.store). We extend the default
  # ShopSessionStorage#store (which only writes the access token) to also
  # reactivate the shop, so a merchant who uninstalls and reinstalls is not
  # left permanently inactive and bounced out of the admin.
  def self.store(auth_session, *_args)
    shop = find_or_initialize_by(shopify_domain: auth_session.shop)
    shop.shopify_token = auth_session.access_token
    shop.active = true
    shop.uninstalled_at = nil
    shop.save!
    shop.id
  end

  def unique_products_count
    vehicle_product_fitments.distinct.count(:product_id)
  end

  # Billing foundation (beyond the original spec). A shop is on a paid plan
  # when billing_plan is not "free" and the subscription has not lapsed.
  def on_paid_plan?
    billing_plan.present? && billing_plan != BillingPlan::FREE && on_active_plan?
  end

  # The merchant's current plan, resolved from the billing_plan column.
  def billing_plan_key
    billing_plan.presence || BillingPlan::FREE
  end

  def on_active_plan?
    billing_expires_at.nil? || billing_expires_at > Time.current
  end

  # The fitment ceiling imposed by the merchant's plan (used to gate bulk
  # imports). Free shops get a limited ceiling, paid tiers raise it.
  def planned_fitment_limit
    plan = BillingPlan.find(billing_plan_key)
    plan ? plan.max_fitments : BillingPlan.default.max_fitments
  end

  def settings
    app_setting || create_app_setting
  end

  private

  def initialize_settings
    create_app_setting if app_setting.blank?
  end
end
