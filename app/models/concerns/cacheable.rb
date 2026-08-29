module Cacheable
  extend ActiveSupport::Concern

  included do
    after_commit :invalidate_cache
  end

  def invalidate_cache
    if respond_to?(:shop_id) && shop_id.present?
      FitmentSearchService.invalidate_shop_cache(shop_id)
    else
      VehicleHierarchyService.invalidate_global_cache
    end
  end
end
