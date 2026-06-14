class ThirdPlacesRankingService
  def initialize(groups = Group.ordered)
    @groups = groups
  end

  def call
    groups.filter_map { |group| GroupStandingService.new(group).third_place }
          .sort_by { |team| [-team.points, -team.goal_difference, -team.goals_for, team.name] }
  end

  private

  attr_reader :groups
end
