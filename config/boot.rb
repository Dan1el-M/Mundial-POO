ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
# Bootsnap can fail on Windows when the project path contains accented characters.
# Rails works normally without it; it only speeds up boot time.
require "bootsnap/setup" unless Gem.win_platform?
