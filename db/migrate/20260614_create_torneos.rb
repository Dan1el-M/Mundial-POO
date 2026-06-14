class CreateTorneos < ActiveRecord::Migration[7.1]
  def change
    create_table :torneos do |t|
      t.string :nombre, null: false
      t.string :etapa_actual, default: "fase_grupos", null: false
      
      # Podio final
      t.references :campeon, foreign_key: { to_table: :selecciones }, null: true
      t.references :subcampeon, foreign_key: { to_table: :selecciones }, null: true
      t.references :tercero, foreign_key: { to_table: :selecciones }, null: true

      t.timestamps
    end

    add_index :torneos, :nombre, unique: true
    add_index :torneos, :etapa_actual
  end
end
