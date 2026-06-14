groups_with_teams = {
  "A" => ["Mexico", "Japan", "Nigeria", "Switzerland"],
  "B" => ["United States", "South Korea", "Ghana", "Croatia"],
  "C" => ["Canada", "Senegal", "Uruguay", "Denmark"],
  "D" => ["Brazil", "Poland", "Australia", "Morocco"],
  "E" => ["Argentina", "Serbia", "Ecuador", "Norway"],
  "F" => ["France", "Chile", "Egypt", "Sweden"],
  "G" => ["Spain", "Cameroon", "Paraguay", "Austria"],
  "H" => ["England", "Tunisia", "Colombia", "Romania"],
  "I" => ["Germany", "Peru", "Ivory Coast", "Scotland"],
  "J" => ["Italy", "Algeria", "Turkey", "Venezuela"],
  "K" => ["Portugal", "Costa Rica", "Ukraine", "Saudi Arabia"],
  "L" => ["Netherlands", "Belgium", "Iran", "New Zealand"]
}.freeze

Match.delete_all
Team.delete_all
Group.delete_all

groups_with_teams.each do |letter, team_names|
  group = Group.create!(letter: letter)

  team_names.each do |team_name|
    Team.create!(name: team_name, group: group)
  end
end

puts "Seeded #{Group.count} groups and #{Team.count} teams."
