class CreateTorneos < ActiveRecord::Migration[7.1]
  def change
    create_table :torneos do |t|
      t.string  :nombre,       null: false

     t.string  :etapa_actual, null: false, default: "fase_grupos"

       t.integer :campeon_id
      t.integer :subcampeon_id
      t.integer :tercero_id

      t.timestamps
    end

    add_index :torneos, :nombre, unique: true

    add_index :torneos, :campeon_id
    add_index :torneos, :subcampeon_id
    add_index :torneos, :tercero_id

    add_foreign_key :torneos, :selecciones, column: :campeon_id
    add_foreign_key :torneos, :selecciones, column: :subcampeon_id
    add_foreign_key :torneos, :selecciones, column: :tercero_id
  end
end