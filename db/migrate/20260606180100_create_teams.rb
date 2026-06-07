class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.references :group, null: false, foreign_key: true
      t.integer :points, null: false, default: 0
      t.integer :goals_for, null: false, default: 0
      t.integer :goals_against, null: false, default: 0
      t.integer :goal_difference, null: false, default: 0

      t.timestamps
    end

    add_index :teams, :name, unique: true
  end
end
