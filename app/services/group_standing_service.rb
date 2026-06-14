class GroupStandingService
  def initialize(group)
    @group = group
  end

  def call
    group.teams.reorder(points: :desc, goal_difference: :desc, goals_for: :desc, name: :asc)
  end

  def top(limit = 2)
    call.limit(limit)
  end

  def third_place
    call.offset(2).first
  end

  private

  attr_reader :group
end
