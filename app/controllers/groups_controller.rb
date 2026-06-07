class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy]

  def index
    @groups = Group.ordered.includes(:teams)
  end

  def show
    @standings = GroupStandingService.new(@group).call
    @matches = @group.matches.includes(:home_team, :away_team)
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      redirect_to groups_path, notice: "Group created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @group.update(group_params)
      redirect_to groups_path, notice: "Group updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @group.destroy
      redirect_to groups_path, notice: "Group removed successfully."
    else
      redirect_to groups_path, alert: @group.errors.full_messages.to_sentence
    end
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def group_params
    params.require(:group).permit(:letter)
  end
end
