require "test_helper"

class RoundAdvancerTest < ActiveSupport::TestCase
  test "creates the next knockout round when every match is complete" do
    group = Group.create!(letter: "B")
    teams = 4.times.map { |index| Team.create!(name: "Knockout Team #{index}", group: group) }

    first_match = KnockoutMatch.create!(
      home_team: teams[0],
      away_team: teams[1],
      home_score: 1,
      away_score: 0,
      round: :semifinals,
      bracket_position: 1
    )

    second_match = KnockoutMatch.create!(
      home_team: teams[2],
      away_team: teams[3],
      home_score: 3,
      away_score: 1,
      round: :semifinals,
      bracket_position: 2
    )

    RoundAdvancer.new(first_match).call
    RoundAdvancer.new(second_match).call

    final_match = KnockoutMatch.find_by(round: :final, bracket_position: 1)
    third_place_match = KnockoutMatch.find_by(round: :third_place, bracket_position: 1)

    assert_not_nil final_match
    assert_not_nil third_place_match
    assert_equal teams[0], final_match.home_team
    assert_equal teams[2], final_match.away_team
    assert_equal teams[1], third_place_match.home_team
    assert_equal teams[3], third_place_match.away_team
  end
end
