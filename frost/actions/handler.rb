# frozen_string_literal: true

module ActionCommands
  extend Discordrb::EventContainer

  application_command(:hug) do |event|
    Actions.call(event, :hug)
  end

  application_command(:nom) do |event|
    Actions.call(event, :nom)
  end

  application_command(:bonk) do |event|
    Actions.call(event, :bonk)
  end

  application_command(:poke) do |event|
    Actions.call(event, :poke)
  end

  application_command(:punch) do |event|
    Actions.call(event, :punch)
  end

  application_command(:angered) do |event|
    Actions.call(event, :angered)
  end
end
