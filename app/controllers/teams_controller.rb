class TeamsController < ApplicationController
  before_action :set_team, only: %i[edit update destroy]
  before_action :set_groups, only: %i[new create edit update]

  def index
    @groups = Group.ordered.includes(:teams)
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to teams_path, notice: "Team created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @team.update(team_params)
      redirect_to teams_path, notice: "Team updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @team.destroy
      redirect_to teams_path, notice: "Team removed successfully."
    else
      redirect_to teams_path, alert: @team.errors.full_messages.to_sentence
    end
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def set_groups
    @groups = Group.ordered
  end

  def team_params
    params.require(:team).permit(:name, :group_id)
  end
end
