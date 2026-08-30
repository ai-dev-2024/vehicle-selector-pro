class Shop < ApplicationRecord
  include ShopifyApp::ShopSessionStorage

  encrypts :shopify_token, deterministic: false if respond_to?(:encrypts)

  # Associations
  has_many :vehicle_product_fitments, dependent: :destroy
  has_many :metafield_sync_logs, dependent: :destroy
  has_one :app_setting, dependent: :destroy
  has_many :vehicles, -> { distinct }, through: :vehicle_product_fitments

  # Validations
  validates :shopify_domain, presence: true, uniqueness: { case_sensitive: false }
  validates :shopify_token, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :uninstalled, -> { where(active: false) }

  # Callbacks
  after_create :initialize_settings

  def api_version
    ShopifyApp.configuration.api_version
  end

  def with_shopify_session(&)
    session = ShopifyAPI::Auth::Session.new(
      shop: shopify_domain,
      access_token: shopify_token
    )
    ShopifyAPI::Utils::SessionUtils.with_session(session, &)
  rescue StandardError => e
    Rails.logger.error("[ShopifySession] Failed for #{shopify_domain}: #{e.message}")
    raise
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

  def fitment_count
    vehicle_product_fitments.count
  end

  def unique_products_count
    vehicle_product_fitments.distinct.count(:product_id)
  end

  def settings
    app_setting || create_app_setting
  end

  private

  def initialize_settings
    create_app_setting if app_setting.blank?
  end
end
