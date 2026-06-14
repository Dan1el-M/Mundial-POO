class AddTorneoToGruposAndPartidos < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:grupos, :torneo_id)
      add_reference :grupos, :torneo, foreign_key: true, null: true
    end

    if column_exists?(:grupos, :torneo_id)
      add_index :grupos, :torneo_id unless index_exists?(:grupos, :torneo_id)
      add_foreign_key :grupos, :torneos unless foreign_key_exists?(:grupos, :torneos)
    end

    unless column_exists?(:partidos, :torneo_id)
      add_reference :partidos, :torneo, foreign_key: true, null: true
    end

    if column_exists?(:partidos, :torneo_id)
      add_index :partidos, :torneo_id unless index_exists?(:partidos, :torneo_id)
      add_foreign_key :partidos, :torneos unless foreign_key_exists?(:partidos, :torneos)
    end
  end
end
