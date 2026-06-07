class RoundAdvancer
  NEXT_ROUNDS = {
    round_of_32: :round_of_16,
    round_of_16: :quarterfinals,
    quarterfinals: :semifinals
  }.freeze
  EXPECTED_MATCHES = {
    round_of_32: 16,
    round_of_16: 8,
    quarterfinals: 4,
    semifinals: 2
  }.freeze

  def initialize(match)
    @match = match
  end

  def call
    return unless match.is_a?(KnockoutMatch) && match.completed? && match.winner_team.present?

    current_round_matches = KnockoutMatch.where(round: match.round).order(:bracket_position).to_a
    return unless current_round_matches.count == EXPECTED_MATCHES.fetch(match.round.to_sym)
    return unless current_round_matches.all? { |round_match| round_match.completed? && round_match.winner_team.present? }

    if match.round.to_sym == :semifinals
      sync_final_rounds(current_round_matches)
    elsif NEXT_ROUNDS.key?(match.round.to_sym)
      sync_standard_round(NEXT_ROUNDS.fetch(match.round.to_sym), current_round_matches.map(&:winner_team))
    end
  end

  private

  attr_reader :match

  def sync_standard_round(next_round, winners)
    winners.each_slice(2).with_index(1) do |teams, index|
      upsert_match(next_round, index, teams)
    end
  end

  def sync_final_rounds(semifinals)
    upsert_match(:final, 1, semifinals.map(&:winner_team))
    upsert_match(:third_place, 1, semifinals.map(&:loser_team))
  end

  def upsert_match(round, position, teams)
    return unless teams.size == 2 && teams.all?

    knockout_match = KnockoutMatch.find_or_initialize_by(round: round, bracket_position: position)
    return if knockout_match.persisted? && knockout_match.completed?

    knockout_match.update!(
      home_team: teams.first,
      away_team: teams.second,
      home_score: nil,
      away_score: nil,
      home_penalty_score: nil,
      away_penalty_score: nil,
      winner_team: nil,
      group: nil
    )
  end
end
