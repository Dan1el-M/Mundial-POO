# Migración independiente para agregar el acrónimo a selecciones ya existentes.
# Se corre DESPUÉS de la migración original (20260606180100_selecciones.rb).
#
# Para aplicarla: rails db:migrate
class AddAcronimoToSelecciones < ActiveRecord::Migration[7.1]
  def up
    # 1. Agrega la columna sin restricción NOT NULL para poder poblarla primero
    add_column :selecciones, :acronimo, :string, limit: 3

    # 2. Genera un acrónimo provisional para cada fila ya existente en la BD,
    #    usando la misma lógica que el modelo (primeras letras de palabras relevantes).
    #    Esto evita el error al intentar poner null: false con datos preexistentes.
    execute <<~SQL
      UPDATE selecciones
      SET acronimo = UPPER(SUBSTR(nombre, 1, 3))
      WHERE acronimo IS NULL
    SQL

    # 3. Una vez que todas las filas tienen valor, aplica la restricción NOT NULL
    change_column_null :selecciones, :acronimo, false

    # 4. Índice único para garantizar que no haya dos equipos con el mismo acrónimo
    add_index :selecciones, :acronimo, unique: true
  end

  def down
    remove_index  :selecciones, :acronimo
    remove_column :selecciones, :acronimo
  end
end