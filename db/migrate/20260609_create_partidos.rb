class CreatePartidos < ActiveRecord::Migration[7.1]
  def change
    create_table :partidos do |t|
      t.integer      :numero_partido,           null: false
      t.string       :estado,                   null: false, default: "programado"
      t.string       :tipo_partido,             null: false
      t.integer      :torneo_id,                null: true
      t.references   :grupo,                    foreign_key: true, null: true
      t.references   :seleccion_local,          foreign_key: { to_table: :selecciones }, null: false
      t.references   :seleccion_visitante,      foreign_key: { to_table: :selecciones }, null: false
      t.references   :ganador,                  foreign_key: { to_table: :selecciones }, null: true
      t.integer      :goles_local,              null: true
      t.integer      :goles_visitante,          null: true
      t.integer      :goles_penales_local,      null: true
      t.integer      :goles_penales_visitante,  null: true

      t.timestamps
    end

    add_index :partidos, :numero_partido
    add_index :partidos, [:tipo_partido, :estado]
  end
end
