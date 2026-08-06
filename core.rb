# frozen_string_literal: true

require "yaml"
require "sequel"
require "discordrb"
require "tzinfo/data"
require "unicode/emoji"
require "rufus-scheduler"
require "selenium-webdriver"

Dir["frost/**/*.rb"].reverse_each { |file| require_relative file }

BOT = Frost::Tundra.new

BOT.include! AdminCommands
BOT.include! ActionCommands

BOT.run
