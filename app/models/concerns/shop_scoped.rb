module ShopScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :shop
    validates :shop, presence: true

    scope :for_shop, ->(shop_or_id) {
      shop_id = shop_or_id.is_a?(Shop) ? shop_or_id.id : shop_or_id
      where(shop_id: shop_id)
    }
  end
end
