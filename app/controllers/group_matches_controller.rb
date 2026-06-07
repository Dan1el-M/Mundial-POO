class GroupMatchesController < ApplicationController
  before_action :set_match, only: %i[edit update destroy]
  before_action :set_groups_and_teams, only: %i[new create edit update]

  def index
    @groups = Group.ordered.includes(matches: %i[home_team away_team])
  end

  def new
    @match = Match.new(round: :group_stage, group_id: params[:group_id])
  end

  def create
    @match = Match.new(group_match_params.merge(round: :group_stage))

    if @match.save
      redirect_to group_matches_path, notice: "Group match created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @match.update(group_match_params)
      redirect_to group_matches_path, notice: "Group match updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @match.destroy
      redirect_to group_matches_path, notice: "Group match removed successfully."
    else
      redirect_to group_matches_path, alert: @match.errors.full_messages.to_sentence
    end
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def set_groups_and_teams
    @groups = Group.ordered
    @teams = Team.includes(:group).order(:name)
  end

  def group_match_params
    params.require(:match).permit(:group_id, :home_team_id, :away_team_id, :home_score, :away_score)
  end
end
