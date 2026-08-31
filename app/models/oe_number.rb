# Original Equipment (OE) part numbers. A merchant maps their products to the
# factory part numbers that cross-reference them (e.g. "51372-TG7-A01" for a
# Honda brake pad), so shoppers can search by the OE number printed on the part
# they already have. Scoped to a shop like every other merchant-owned record.
class OeNumber < ApplicationRecord
  include ShopScoped

  validates :product_id, presence: true
  validates :oe_number, presence: true, uniqueness: { scope: :shop_id, case_sensitive: false }

  before_save { self.oe_number = oe_number.to_s.strip.upcase }

  scope :for_product, ->(product_id) { where(product_id: product_id.to_s) }
  scope :matching, ->(term) { where("oe_number LIKE ?", "%#{term.to_s.strip.upcase}%") }

  # Returns product IDs whose OE cross-reference matches the search term.
  # Used by the app proxy search to resolve an OE-number query to products.
  def self.product_ids_for(shop, term)
    return [] if term.blank?

    shop.oe_numbers.matching(term).distinct.pluck(:product_id)
  end
end
