class GroupMatchesController < ApplicationController
  before_action :set_match, only: %i[edit update destroy]
  before_action :set_groups_and_teams, only: %i[new create edit update]

  def index
    @groups = Group.ordered.includes(matches: %i[home_team away_team])
  end

  def generate_calendar
    @groups = Group.ordered.includes(:teams, matches: %i[home_team away_team])
    incomplete_groups = @groups.select { |group| group.teams.size != 4 }

    if incomplete_groups.any?
      letters = incomplete_groups.map { |group| "Grupo #{group.letter}" }.join(", ")
      redirect_to group_matches_path, alert: "No se puede generar el calendario. Revisa estos grupos: #{letters}."
      return
    end

    created_matches = generate_missing_group_matches(@groups)

    redirect_to calendar_group_matches_path,
                notice: created_matches.positive? ? "Calendario generado con #{created_matches} partido(s)." : "El calendario ya estaba generado."
  end

  def calendar
    @groups = Group.ordered.includes(:teams, matches: %i[home_team away_team])
    @selected_group = Group.find_by(id: params[:group_id]) || @groups.first
    @matches = @selected_group&.matches&.includes(:home_team, :away_team) || Match.none
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
      redirect_after_match_update(notice: "Marcador registrado correctamente.")
    else
      redirect_after_match_update(alert: @match.errors.full_messages.to_sentence)
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

  def redirect_after_match_update(**message)
    if params[:redirect_to_calendar].present?
      redirect_to calendar_group_matches_path(group_id: @match.group_id), message
    else
      redirect_to group_matches_path, message
    end
  end

  def generate_missing_group_matches(groups)
    groups.sum do |group|
      teams = group.teams.to_a

      teams.combination(2).count do |home_team, away_team|
        next false if group_pairing_exists?(group, home_team, away_team)

        Match.create!(group: group, home_team: home_team, away_team: away_team, round: :group_stage)
        true
      end
    end
  end

  def group_pairing_exists?(group, home_team, away_team)
    group.matches.any? do |match|
      [match.home_team_id, match.away_team_id].sort == [home_team.id, away_team.id].sort
    end
  end
end
