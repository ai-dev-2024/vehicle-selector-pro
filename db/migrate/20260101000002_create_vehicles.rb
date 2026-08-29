class CreateVehicles < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicles do |t|
      t.integer :year, null: false
      t.string :make, null: false
      t.string :model, null: false
      t.string :trim
      t.string :engine
      t.string :fuel_type
      t.string :transmission
      t.string :drivetrain
      t.string :body_style
      t.string :standard_id # ACES BaseVehicleID / VCdb ID
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :vehicles, [:year, :make, :model, :trim, :engine], unique: true, name: 'index_vehicles_on_ymmte_unique'
    add_index :vehicles, :year
    add_index :vehicles, [:year, :make]
    add_index :vehicles, [:year, :make, :model]
    add_index :vehicles, :make
    add_index :vehicles, :model
  end
end
