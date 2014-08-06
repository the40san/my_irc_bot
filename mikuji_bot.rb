require 'cinch'
require 'configatron'

class Mikuji
  include Cinch::Plugin

  match(/.*mikuji.*/, {use_prefix: false, use_suffix: false})

  def execute(m)
    user_list = m.channel.users.flatten.select{|o| o.is_a?(Cinch::User) && !o.is_a?(Cinch::Bot) }.map(&:nick)
    m.reply "The task will be assigned to #{user_list.shuffle.first} !"
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    configatron.configure_from_yaml("config/config.yml")
    #c.server = "irc.tokyo.optim.co.jp"
    #c.nick = "mikuji_bot"
    #c.channels = ["#mikuji"]
    #c.plugins.plugins = [Mikuji]

    c.server   = configatron.defaults.irc.server_address.to_s
    c.channels = configatron.defaults.irc.joining_channels
    c.nick     = configatron.defaults.bot.nick
    #c.plugins.plugins = [Mikuji]
  end
end

bot.start
