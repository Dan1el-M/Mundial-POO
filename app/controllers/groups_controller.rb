class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy]

  def index
    @groups = Group.ordered.includes(:teams)

    respond_to do |format|
      format.html
      format.json do
        render json: @groups.map { |group|
          {
            id: group.id,
            letter: group.letter,
            teams: group.teams.order(:name).map { |team| { id: team.id, name: team.name } }
          }
        }
      end
    end
  end

  def show
    @standings = GroupStandingService.new(@group).call
    @matches = @group.matches.includes(:home_team, :away_team)
    @groups = Group.ordered
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)

    if @group.save
      respond_to do |format|
        format.html { redirect_to groups_path, notice: "Group created successfully." }
        format.json { render json: { message: "Grupo agregado correctamente.", letter: @group.letter }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { message: @group.errors.full_messages.to_sentence }, status: :unprocessable_entity }
      end
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
