class VehicleHierarchyService
  GLOBAL_CACHE_KEY = "vsp/global_ymm_tree"

  def self.invalidate_global_cache
    Rails.cache.delete(GLOBAL_CACHE_KEY)
  end

  def self.full_tree
    Rails.cache.fetch(GLOBAL_CACHE_KEY, expires_in: 24.hours) do
      build_full_tree
    end
  end

  def self.build_full_tree
    tree = {}
    Vehicle.active.order(year: :desc, make: :asc, model: :asc).find_each do |veh|
      tree[veh.year] ||= {}
      tree[veh.year][veh.make] ||= {}
      tree[veh.year][veh.make][veh.model] ||= { trims: [], engines: [] }

      tree[veh.year][veh.make][veh.model][:trims] << veh.trim if veh.trim.present?
      tree[veh.year][veh.make][veh.model][:engines] << veh.engine if veh.engine.present?
    end

    # De-duplicate arrays
    tree.each do |_yr, makes|
      makes.each do |_mk, models|
        models.each do |_mdl, specs|
          specs[:trims].uniq!
          specs[:engines].uniq!
        end
      end
    end

    tree
  end
end
