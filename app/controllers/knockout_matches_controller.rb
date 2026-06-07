class KnockoutMatchesController < ApplicationController
  before_action :set_knockout_match, only: %i[edit update]

  def index
    @matches_by_round = KnockoutMatch.includes(:home_team, :away_team, :winner_team)
                                     .ordered
                                     .group_by(&:round)
  end

  def edit; end

  def update
    if @knockout_match.update(knockout_match_params)
      redirect_to knockout_matches_path, notice: "Knockout result updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_knockout_match
    @knockout_match = KnockoutMatch.find(params[:id])
  end

  def knockout_match_params
    params.require(:knockout_match).permit(:home_score, :away_score, :home_penalty_score, :away_penalty_score)
  end
end
