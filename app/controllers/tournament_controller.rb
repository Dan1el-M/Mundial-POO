class TournamentController < ApplicationController
  def standings
    @groups = Group.ordered.includes(:teams)
  end

  def qualified
    @top_two_by_group = Group.ordered.index_with { |group| GroupStandingService.new(group).top(2).to_a }
    @best_third_places = ThirdPlacesRankingService.new.call.first(8)
    @qualified_teams = @top_two_by_group.values.flatten + @best_third_places
    @bracket_ready = @qualified_teams.size == 32
    @round_of_32_exists = KnockoutMatch.round_of_32.exists?
  end

  def champion
    @final_match = KnockoutMatch.final.first
    @third_place_match = KnockoutMatch.third_place.first
    @champion = @final_match&.winner_team if @final_match&.completed?
    @runner_up = if @final_match&.completed? && @final_match.winner_team.present?
                   @final_match.winner_team == @final_match.home_team ? @final_match.away_team : @final_match.home_team
                 end
    @third_place = @third_place_match&.winner_team if @third_place_match&.completed?
  end

  def generate_bracket
    KnockoutBracketService.new.generate!
    redirect_to knockout_matches_path, notice: "Knockout bracket generated successfully."
  rescue ArgumentError => e
    redirect_to qualified_tournament_path, alert: e.message
  end
end
