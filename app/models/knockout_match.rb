class KnockoutMatch < Match
  validates :group, absence: true
  validates :bracket_position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :penalty_rules

  after_commit :advance_bracket, on: %i[create update]

  scope :ordered, -> { order(:round, :bracket_position) }

  def loser_team
    return if winner_team.blank?

    winner_team_id == home_team_id ? away_team : home_team
  end

  private

  def winner_from_scores
    return if home_team.blank? || away_team.blank?
    return if home_score.blank? || away_score.blank?

    return home_team if home_score > away_score
    return away_team if away_score > home_score
    return if home_penalty_score.blank? || away_penalty_score.blank?

    home_penalty_score > away_penalty_score ? home_team : away_team
  end

  def penalty_rules
    return unless completed?

    if draw?
      if home_penalty_score.blank? || away_penalty_score.blank?
        errors.add(:base, "Penalty scores are required after a knockout draw")
      elsif home_penalty_score == away_penalty_score
        errors.add(:base, "Penalty scores must determine a winner")
      end
    elsif home_penalty_score.present? || away_penalty_score.present?
      errors.add(:base, "Penalty scores can only be registered after a draw")
    end
  end

  def advance_bracket
    return unless completed? && winner_team.present?

    RoundAdvancer.new(self).call
  end
end
