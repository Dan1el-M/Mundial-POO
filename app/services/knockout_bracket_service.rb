class KnockoutBracketService
  TOTAL_QUALIFIERS = 32

  def qualified_teams
    direct_qualifiers + best_third_places
  end

  def generate!
    teams = qualified_teams
    raise ArgumentError, "Exactly 32 teams are required to generate the bracket" unless teams.size == TOTAL_QUALIFIERS

    pairings = teams.each_with_index.map do |team, index|
      [team, teams.reverse[index]]
    end.first(TOTAL_QUALIFIERS / 2)

    KnockoutMatch.transaction do
      pairings.each_with_index do |(home_team, away_team), index|
        match = KnockoutMatch.find_or_initialize_by(round: :round_of_32, bracket_position: index + 1)
        next if match.persisted? && match.completed?

        match.update!(
          home_team: home_team,
          away_team: away_team,
          home_score: nil,
          away_score: nil,
          home_penalty_score: nil,
          away_penalty_score: nil,
          winner_team: nil,
          group: nil
        )
      end
    end
  end

  private

  def direct_qualifiers
    Group.ordered.flat_map do |group|
      GroupStandingService.new(group).top(2).to_a
    end
  end

  def best_third_places
    ThirdPlacesRankingService.new.call.first(8)
  end
end
