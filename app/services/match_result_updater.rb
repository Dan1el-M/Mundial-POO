class MatchResultUpdater
  def initialize(match: nil, group: nil)
    @match = match
    @group = group || match&.group
  end

  def call
    return if group.blank?

    # Rebuild the table from the persisted results so edits remain idempotent.
    teams = group.teams.to_a
    stats_by_team_id = teams.index_by(&:id).transform_values do
      { points: 0, goals_for: 0, goals_against: 0, goal_difference: 0 }
    end

    group.matches.completed.each do |match_record|
      apply_stats(stats_by_team_id[match_record.home_team_id], scored: match_record.home_score, conceded: match_record.away_score)
      apply_stats(stats_by_team_id[match_record.away_team_id], scored: match_record.away_score, conceded: match_record.home_score)
      assign_points(stats_by_team_id[match_record.home_team_id], stats_by_team_id[match_record.away_team_id], match_record)
    end

    Team.transaction do
      teams.each do |team|
        team.update_columns(stats_by_team_id.fetch(team.id))
      end
    end
  end

  private

  attr_reader :group, :match

  def apply_stats(team_stats, scored:, conceded:)
    team_stats[:goals_for] += scored
    team_stats[:goals_against] += conceded
    team_stats[:goal_difference] = team_stats[:goals_for] - team_stats[:goals_against]
  end

  def assign_points(home_stats, away_stats, match_record)
    if match_record.home_score > match_record.away_score
      home_stats[:points] += 3
    elsif match_record.home_score < match_record.away_score
      away_stats[:points] += 3
    else
      home_stats[:points] += 1
      away_stats[:points] += 1
    end
  end
end
