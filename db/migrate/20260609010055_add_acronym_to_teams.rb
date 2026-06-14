class AddAcronymToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :acronym, :string
  end
end
