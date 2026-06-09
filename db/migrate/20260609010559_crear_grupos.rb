class CrearGrupos < ActiveRecord::Migration[7.1]
  def change
    create_table :grupos do |t|
      t.string :letra, null: false

      t.timestamps
    end

    add_index :grupos, :letra, unique: true
  end
end