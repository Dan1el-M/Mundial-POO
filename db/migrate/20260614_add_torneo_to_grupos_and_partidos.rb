class AddTorneoToGruposAndPartidos < ActiveRecord::Migration[7.1]
  def change
    # Agregar FK a Grupo
    add_reference :grupos, :torneo, foreign_key: true, null: true
    add_index :grupos, :torneo_id

    # Agregar FK a Partido
    add_reference :partidos, :torneo, foreign_key: true, null: true
    add_index :partidos, :torneo_id
  end
end
