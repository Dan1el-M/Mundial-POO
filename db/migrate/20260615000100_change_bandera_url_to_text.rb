class ChangeBanderaUrlToText < ActiveRecord::Migration[7.1]
  def change
    change_column :selecciones, :bandera_url, :text
  end
end
