require "test_helper"

class GroupStandingServiceTest < ActiveSupport::TestCase
  test "rebuilds standings after group results" do
    group = Group.create!(letter: "A")
    mexico = Team.create!(name: "Mexico Test", group: group)
    japan = Team.create!(name: "Japan Test", group: group)
    ghana = Team.create!(name: "Ghana Test", group: group)
    croatia = Team.create!(name: "Croatia Test", group: group)

    Match.create!(group: group, home_team: mexico, away_team: japan, home_score: 2, away_score: 0, round: :group_stage)
    Match.create!(group: group, home_team: ghana, away_team: croatia, home_score: 1, away_score: 1, round: :group_stage)

    MatchResultUpdater.new(group: group).call

    standings = GroupStandingService.new(group).call.to_a

    assert_equal [mexico, croatia, ghana, japan].map(&:name), standings.map(&:name)
    assert_equal 3, mexico.reload.points
    assert_equal 2, mexico.goals_for
    assert_equal 0, mexico.goals_against
    assert_equal 2, mexico.goal_difference
    assert_equal 1, croatia.reload.points
    assert_equal 1, ghana.reload.points
    assert_equal 0, japan.reload.points
  end
end
