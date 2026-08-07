# frozen_string_literal: true

require "yaml"
require "sequel"
require "discordrb"
require "tzinfo/data"
require "unicode/emoji"
require "rufus-scheduler"
require "selenium-webdriver"

module Frost
  # Helper functions used everywhere.
  module Utilities
    # Take an integer and append an ordinal suffix at the end.
    # @param integer [Integer] An integer between 1-31 (inclusive).
    # @return [String] The stringified integer with an ordinal suffix.
    def self.ordinal(integer)
      case integer
      when 1, 21, 31
        "#{integer}st"
      when 2, 22
        "#{integer}nd"
      when 3, 23
        "#{integer}rd"
      else
        "#{integer}th"
      end
    end

    # Take an integer and add a comma every 3 digits.
    # @param integer [Integer] An integer that should be comma-delimited.
    # @return [String] The stringified integer delimited by a comma every 3-digits.
    def self.delimit(integer)
      integer.to_s.tap { it.gsub!(/\B(?=(\d{3})+(?!\d))/, ",") }
    end

    # Take a string and convert it to its snake-case representation.
    # @param string [String, nil] A string that should be converted to snake-case.
    # @return [String, nil] The string that has been converted to snake-case format.
    def self.to_snake_case(string)
      string ? string.downcase.gsub(/[^a-z]+/, "_").gsub(/^_|_$/, "") : nil
    end
  end

  # The configuration for the current bot.
  class Configuration
    # @return [Integer] the ID of the bot owner.
    attr_reader :owner_id

    # @return [String] the auth token of the bot.
    attr_reader :bot_token

    # @return [String] the URI of the database. The URL must
    #   use the `postgres://` URI scheme or the connection will fail.
    attr_reader :database_uri

    # @return [ChapterInfo] the information about the cron job that will run
    #   to update the channel that shows the release date of the next chapter.
    attr_reader :chapter_info

    # @!visibility private
    def initialize
      data = YAML.load_file("config.yml")
      @owner_id = Integer(data["Discord"]["OWNER"])
      @bot_token = String(data["Discord"]["TOKEN"])
      @database_uri = String(data["Postgres"]["URL"])
      @chapter_info = ChapterInfo.new(data["Chapter"]).freeze
    end

    # The configuration for the release channel cron job.
    class ChapterInfo
      # @return [Integer] the ID of the channel that displays the
      #   next chapter's release date.
      attr_reader :channel_id

      # @return [String] the URL where the {#website_css} is located at.
      attr_reader :website_url

      # @return [String] the CSS element containing the chapter's release date.
      attr_reader :website_css

      # @!visibility private
      def initialize(data)
        @website_url = String(data["LINK"])
        @channel_id = Integer(data["CHANNEL"])
        @website_css = String(data["ELEMENT"])
      end

      # Get the release channel that the configuration references.
      # @return [Channel] The release channel that the configuration references.
      def channel
        BOT.channel(@channel_id) if @channel_id
      end
    end
  end

  # The wrapper for the bot and the database.
  class Tundra
    # @return [Configuration] the configuration for the bot.
    attr_reader :config

    # @return [Discordrb::Bot] the discord connection for the bot.
    attr_reader :discord

    # @return [Sequel::Postgres::Database] the database for the bot.
    attr_reader :database

    # @!visibility private
    def initialize
      @config = Configuration.new.freeze

      bot = {
        ignore_bots: true,
        token: @config.bot_token,
        intents: %i[
          guilds
          guild_messages
          guild_expressions
          guild_message_content
        ]
      }

      @discord = Discordrb::Bot.new(**bot)

      # NOTE: Due to how we store birthdays, we should always
      # treat timestamp columns as being in UTC. I haven't tested
      # what happens if I remove this, and I don't really plan on
      # finding out either.
      Sequel.default_timezone = :utc

      db = {
        pool_timeout: 300,
        max_connections: 100,
        extensions: %i[
          pg_streaming
          connection_validator
          pg_auto_parameterize
        ]
      }

      @database = Sequel.connect(@config.database_uri, **db)

      # NOTE: Because we are using postgres through the NEON
      # platform, we can only keep connections around for a total
      # of 5 minutes, since the database will scale to zero after
      # 5-minutes of inactivity.
      @database.pool.connection_validation_timeout = (60 * 5)

      return unless ENV["REGISTER_COMMANDS"] == "true"

      Frost::Commands.register_application_commands(@discord)
    end
  end
end

Dir["frost/**/*.rb"].reverse_each { |file| require_relative file }

BOT = Frost::Tundra.new

BOT.discord.include! AdminCommands
BOT.discord.include! EventCommands
BOT.discord.include! ActionCommands
BOT.discord.include! BoosterCommands
BOT.discord.include! BirthdayCommands
BOT.discord.include! ModerationCommands

BOT.discord.run
