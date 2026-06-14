class CreateSelecciones < ActiveRecord::Migration[7.1]
  def change
    create_table :selecciones do |t|
      t.string     :nombre,           null: false
      t.references :grupo,            null: false, foreign_key: true
      t.integer    :puntos,           null: false, default: 0
      t.integer    :goles_favor,      null: false, default: 0
      t.integer    :goles_contra,     null: false, default: 0
      t.integer    :diferencia_goles, null: false, default: 0

      t.timestamps
    end

    add_index :selecciones, :nombre, unique: true
  end
end