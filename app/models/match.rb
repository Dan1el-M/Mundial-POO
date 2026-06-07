class Match < ApplicationRecord
  ROUND_ORDER = {
    group_stage: 0,
    round_of_32: 1,
    round_of_16: 2,
    quarterfinals: 3,
    semifinals: 4,
    third_place: 5,
    final: 6
  }.freeze

  belongs_to :group, optional: true
  belongs_to :home_team, class_name: "Team", inverse_of: :home_matches
  belongs_to :away_team, class_name: "Team", inverse_of: :away_matches
  belongs_to :winner_team, class_name: "Team", optional: true, inverse_of: :won_matches

  enum :round, ROUND_ORDER, validate: true

  before_validation :set_group_from_teams, if: -> { group.blank? && home_team.present? && away_team.present? && group_stage? }
  before_validation :sync_winner_team
  before_destroy :store_group_id
  after_commit :refresh_group_statistics, on: %i[create update]
  after_destroy :refresh_group_statistics_after_destroy

  validates :home_team, :away_team, presence: true
  validates :home_score, :away_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :home_penalty_score, :away_penalty_score, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :different_teams
  validate :score_pair_presence
  validate :group_stage_consistency
  validate :teams_must_share_group_in_group_stage
  validate :unique_group_pairing, if: :validate_group_pairing?

  scope :completed, -> { where.not(home_score: nil, away_score: nil) }

  def completed?
    home_score.present? && away_score.present?
  end

  def draw?
    completed? && home_score == away_score
  end

  def knockout?
    self.class.name == "KnockoutMatch"
  end

  def group_stage?
    !knockout?
  end

  def round_name
    round.humanize
  end

  private

  def validate_group_pairing?
    group_stage? && group.present? && home_team.present? && away_team.present?
  end

  def different_teams
    return if home_team_id.blank? || away_team_id.blank?

    errors.add(:away_team, "must be different from the home team") if home_team_id == away_team_id
  end

  def score_pair_presence
    return if home_score.present? == away_score.present?

    errors.add(:base, "Both scores must be provided together")
  end

  def group_stage_consistency
    if group_stage? && round.to_s != "group_stage"
      errors.add(:round, "must be group stage for regular matches")
    elsif knockout? && round.to_s == "group_stage"
      errors.add(:round, "must be a knockout round for knockout matches")
    end
  end

  def teams_must_share_group_in_group_stage
    return unless group_stage?
    return if home_team.blank? || away_team.blank?

    if home_team.group_id != away_team.group_id
      errors.add(:base, "Both teams must belong to the same group")
      return
    end

    errors.add(:group, "must match the teams group") if group.present? && group_id != home_team.group_id
  end

  def unique_group_pairing
    duplicate_exists = Match.where(type: nil, group_id: group_id)
                            .where.not(id: id)
                            .where(
                              "(home_team_id = :home AND away_team_id = :away) OR (home_team_id = :away AND away_team_id = :home)",
                              home: home_team_id,
                              away: away_team_id
                            )
                            .exists?

    errors.add(:base, "This group match has already been registered") if duplicate_exists
  end

  def set_group_from_teams
    self.group = home_team.group if home_team.group_id == away_team.group_id
  end

  def sync_winner_team
    self.winner_team = winner_from_scores
  end

  def winner_from_scores
    return if home_team.blank? || away_team.blank?
    return if home_score.blank? || away_score.blank?

    return home_team if home_score > away_score
    return away_team if away_score > home_score

    nil
  end

  def store_group_id
    @group_id_before_destroy = group_id
  end

  def refresh_group_statistics
    return unless group_stage? && group.present?

    MatchResultUpdater.new(group: group).call
  end

  def refresh_group_statistics_after_destroy
    return unless group_stage? && @group_id_before_destroy.present?

    MatchResultUpdater.new(group: Group.find_by(id: @group_id_before_destroy)).call
  end
end
