class Team < ApplicationRecord
  belongs_to :group

  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :restrict_with_error, inverse_of: :home_team
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :restrict_with_error, inverse_of: :away_team
  has_many :won_matches, class_name: "Match", foreign_key: :winner_team_id, dependent: :nullify, inverse_of: :winner_team

  validates :name, presence: true, uniqueness: true
  validates :points, :goals_for, :goals_against, :goal_difference, numericality: { only_integer: true }
  validate :group_capacity

  before_validation :sync_goal_difference

  scope :table_order, -> { order(points: :desc, goal_difference: :desc, goals_for: :desc, name: :asc) }

  def matches
    Match.where("home_team_id = :team_id OR away_team_id = :team_id", team_id: id)
  end

  def stats_reset!
    update_columns(points: 0, goals_for: 0, goals_against: 0, goal_difference: 0)
  end

  private

  def sync_goal_difference
    self.goal_difference = goals_for.to_i - goals_against.to_i
  end

  def group_capacity
    return if group.blank?

    teams_in_group = group.teams.where.not(id: id).count
    errors.add(:group, "already has four teams assigned") if teams_in_group >= 4
  end
end
