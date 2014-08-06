require 'cinch'
require 'json'
require 'configatron'

class Mikuji
  include Cinch::Plugin

  match(/.*mikuji.*/, {use_prefix: false, use_suffix: false})

  def execute(m)
    user_list = m.channel.users.flatten.select{|o| o.is_a?(Cinch::User) && !o.is_a?(Cinch::Bot) }.map(&:nick)
    m.reply "The task will be assigned to #{user_list.shuffle.first} !"
  end
end

class Qiita
  include Cinch::Plugin

  timer 180, method: :report_items

  def report_items
    @reported_uuid ||= []
    items = JSON.parse(`curl -G https://qiita.com/api/v1/items`)

    items.reject! {|h| @reported_uuid.include?(h["uuid"]) }

    items.each do |i|
      Channel(configatron.defaults.qiita.irc_channel).send(i["title"])
      Channel(configatron.defaults.qiita.irc_channel).send(i["url"])
      Channel(configatron.defaults.qiita.irc_channel).send(" ")
      @reported_uuid << i["uuid"]
      sleep(1)
    end
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    configatron.configure_from_yaml("config/config.yml")
    c.server   = configatron.defaults.irc.server_address.to_s
    c.channels = configatron.defaults.irc.joining_channels
    c.nick     = configatron.defaults.bot.nick
    c.plugins.plugins = [Mikuji, Qiita]
  end
end

bot.start
