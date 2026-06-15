class AddBanderaUrlToSelecciones < ActiveRecord::Migration[7.1]
  def change
    return if column_exists?(:selecciones, :bandera_url)

    add_column :selecciones, :bandera_url, :string
  end
end
