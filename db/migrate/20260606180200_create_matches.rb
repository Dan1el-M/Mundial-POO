class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.string :type
      t.references :group, foreign_key: true
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }
      t.integer :home_score
      t.integer :away_score
      t.integer :home_penalty_score
      t.integer :away_penalty_score
      t.integer :round, null: false, default: 0
      t.integer :bracket_position
      t.references :winner_team, foreign_key: { to_table: :teams }

      t.timestamps
    end

    add_index :matches, :type
    add_index :matches, %i[round bracket_position]
  end
end
