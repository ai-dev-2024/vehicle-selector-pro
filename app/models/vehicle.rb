class Vehicle < ApplicationRecord
  include Cacheable

  # Associations
  has_many :vehicle_product_fitments, dependent: :destroy
  has_many :shops, -> { distinct }, through: :vehicle_product_fitments

  # Validations
  validates :year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1900, less_than_or_equal_to: 2100 }
  validates :make, presence: true
  validates :model, presence: true
  validates :year, uniqueness: {
    scope: [:make, :model, :trim, :engine],
    message: "configuration already exists for this Year/Make/Model/Trim/Engine combination"
  }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_year, ->(y) { where(year: y) if y.present? }
  scope :by_make, ->(m) { where('LOWER(make) = ?', m.to_s.downcase.strip) if m.present? }
  scope :by_model, ->(mod) { where('LOWER(model) = ?', mod.to_s.downcase.strip) if mod.present? }
  scope :by_trim, ->(t) { where('LOWER(trim) = ?', t.to_s.downcase.strip) if t.present? }
  scope :by_engine, ->(e) { where('LOWER(engine) = ?', e.to_s.downcase.strip) if e.present? }

  # Class Methods for Cascading Dropdowns
  def self.distinct_years
    active.distinct.order(year: :desc).pluck(:year)
  end

  def self.distinct_makes_for_year(year)
    active.by_year(year).distinct.order(:make).pluck(:make)
  end

  def self.distinct_models_for(year:, make:)
    active.by_year(year).by_make(make).distinct.order(:model).pluck(:model)
  end

  def self.distinct_trims_for(year:, make:, model:)
    active.by_year(year).by_make(make).by_model(model)
          .where.not(trim: [nil, ''])
          .distinct.order(:trim).pluck(:trim)
  end

  def self.distinct_engines_for(year:, make:, model:, trim: nil)
    query = active.by_year(year).by_make(make).by_model(model)
    query = query.by_trim(trim) if trim.present?
    query.where.not(engine: [nil, '']).distinct.order(:engine).pluck(:engine)
  end

  # Instance Methods
  def display_name
    parts = [year, make, model, trim, engine].compact_blank
    parts.join(' ')
  end

  def short_name
    "#{year} #{make} #{model}"
  end

  def to_h
    {
      id: id,
      year: year,
      make: make,
      model: model,
      trim: trim,
      engine: engine,
      drivetrain: drivetrain,
      body_style: body_style,
      display_name: display_name
    }
  end

  def to_ymm_key
    [year, make.downcase, model.downcase, trim.to_s.downcase, engine.to_s.downcase].join('|')
  end
end
