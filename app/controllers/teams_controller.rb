class TeamsController < ApplicationController
  before_action :set_team, only: %i[edit update destroy]
  before_action :set_groups, only: %i[new create edit update]

  PER_PAGE = 10

  def index
    @groups = Group.ordered.includes(:teams)
    @available_group_letters = Group::LETTERS - @groups.pluck(:letter)
    @current_page = params[:page].to_i.positive? ? params[:page].to_i : 1
    # Build a scope that can be filtered before counting/pagination
    scope = Team.includes(:group).order(:name)

    # Allow filtering by group letter via params[:group_letter]
    if params[:group_letter].present? && params[:group_letter] != 'all'
      scope = scope.joins(:group).where(groups: { letter: params[:group_letter] })
    end

    @total_teams = scope.count
    @total_pages = (@total_teams / PER_PAGE.to_f).ceil
    @total_pages = 1 if @total_pages.zero?
    @current_page = @total_pages if @current_page > @total_pages
    @teams = scope.offset((@current_page - 1) * PER_PAGE).limit(PER_PAGE)
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to teams_path, notice: "Team created successfully."
    else
      # Prepare variables used by index so we can render the teams list with the form and errors
      @groups = Group.ordered.includes(:teams)
      @available_group_letters = Group::LETTERS - @groups.pluck(:letter)
      @current_page = params[:page].to_i.positive? ? params[:page].to_i : 1

      scope = Team.includes(:group).order(:name)
      if params[:group_letter].present? && params[:group_letter] != 'all'
        scope = scope.joins(:group).where(groups: { letter: params[:group_letter] })
      end

      @total_teams = scope.count
      @total_pages = (@total_teams / PER_PAGE.to_f).ceil
      @total_pages = 1 if @total_pages.zero?
      @current_page = @total_pages if @current_page > @total_pages
      @teams = scope.offset((@current_page - 1) * PER_PAGE).limit(PER_PAGE)

      # Build Spanish-friendly error messages from ActiveModel errors
      raw_messages = @team.errors.full_messages
      spanish = raw_messages.map do |msg|
        case msg
        when /can't be blank/i
          # extract attribute name
          attr = msg.split(" ").first
          "#{attr.humanize} no puede estar vacío"
        when /has already been taken/i
          attr = msg.split(" ").first
          "#{attr.humanize} ya está en uso"
        when /already has four teams assigned/i, /four teams/i
          "El grupo ya tiene el máximo de selecciones (4)."
        else
          # default: return the original message (can be english)
          msg
        end
      end

      # If any blank errors exist, add a concise header
      if spanish.any? { |m| m =~ /no puede estar vacío/i }
        spanish.unshift('Campos faltantes') unless spanish.first == 'Campos faltantes'
      end

      @validation_errors = spanish.uniq
      flash.now[:alert] = @validation_errors.join('. ')
      render :index, status: :unprocessable_entity
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
    params.require(:team).permit(:name, :acronym, :group_id, :points, :goals_for, :goals_against, :goal_difference)
  end
end
