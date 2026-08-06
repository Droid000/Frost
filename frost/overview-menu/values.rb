# frozen_string_literal: true

module Frost::Overview
  # Content for the landing page.
  ELEMENTS = {
    main_menu_greeting: "Hi! Welcome to my help page. Use the dropdown menu below to view a category.\n\n**About Me**\nI was made by droid00000. My code is open source and can be viewed [here!](https://github.com/Droid00000/Frost)",
    statistics: "**Stats**\nI'm on %s servers with a total of %s members and %s channels."
  }.freeze

  # Add a select menu to a container for an interaction initiated by a basic user.
  def self.basic_menu(container, event)
    base_state = {
      min_values: 1,
      custom_id: "settings",
      placeholder: "Pick a category...",
      disabled: !(event.guild_integration? && event.user.can_manage_roles?)
    }

    container.row do |action_row|
      action_row.select_menu(**base_state) do |menu|
        menu.option(
          label: "Birthdays",
          value: "Birthdays",
          emoji: "733787070123737109",
          description: "Settings for server birthdays."
        )

        menu.option(
          label: "Boosters",
          value: "Boosters",
          emoji: "1320971944627146752",
          description: "Settings for server boosters."
        )
      end
    end
  end

  # Add a select menu to a container for an interaction initiated by the bot owner.
  def self.owner_menu(container, event)
    base_state = {
      min_values: 1,
      custom_id: "settings",
      placeholder: "Pick a category..."
    }

    container.row do |action_row|
      action_row.select_menu(**base_state) do |menu|
        if event.guild_integration?
          menu.option(
            label: "Birthdays",
            value: "Birthdays",
            emoji: "733787070123737109",
            description: "Settings for server birthdays."
          )

          menu.option(
            label: "Boosters",
            value: "Boosters",
            emoji: "1320971944627146752",
            description: "Settings for server boosters."
          )
        end

        menu.option(
          label: "Settings",
          value: "Settings",
          emoji: "1449277904147054725",
          description: "Settings for the application."
        )
      end
    end
  end

  # Generate text containing information about the bot's statistics and maintainer.
  def self.overview_text(bot)
    statistics = format(
      ELEMENTS[:statistics],
      Utilities.delimit(bot.guilds.size),
      Utilities.delimit(bot.guilds.sum { |_, guild| guild.member_count }),
      Utilities.delimit(bot.guilds.sum { |_, guild| guild.channels.size })
    )

    "#{ELEMENTS[:main_menu_greeting]}\n\n#{statistics}"
  end
end
