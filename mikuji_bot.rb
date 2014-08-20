require 'cinch'
require 'json'
require 'configatron'
require 'nokogiri'

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

class PleaseDoReview
  include Cinch::Plugin

  timer 60, method: :check_report

  def check_report
    h = Time.now.hour
    m = Time.now.min

    print_message if configatron.defaults.please_do_review.hour == h && configatron.defaults.please_do_review.min == m
  end

  def print_message
    report_command = "curl --user #{configatron.defaults.please_do_review.user}:#{configatron.defaults.please_do_review.password} -L #{configatron.defaults.please_do_review.trac_report_url}"
    html = `#{report_command}`
    report_num = Nokogiri::HTML.parse(html).css(".numrows").first.children.text.match(/\d+/)[0]


    Channel(configatron.defaults.please_do_review.irc_channel).send(configatron.defaults.please_do_review.frame);
    Channel(configatron.defaults.please_do_review.irc_channel).send(configatron.defaults.please_do_review.message);
    Channel(configatron.defaults.please_do_review.irc_channel).send("#{configatron.defaults.please_do_review.count_message_prefix}#{report_num}#{configatron.defaults.please_do_review.count_message_suffix}");

    Channel(configatron.defaults.please_do_review.irc_channel).send(" ");
    Channel(configatron.defaults.please_do_review.irc_channel).send(configatron.defaults.please_do_review.trac_report_url);

    Channel(configatron.defaults.please_do_review.irc_channel).send(configatron.defaults.please_do_review.frame);

    sleep(10)
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    configatron.configure_from_yaml("config/config.yml")
    c.server   = configatron.defaults.irc.server_address.to_s
    c.channels = configatron.defaults.irc.joining_channels
    c.nick     = configatron.defaults.bot.nick
    c.plugins.plugins = [Mikuji, Qiita, PleaseDoReview]
  end
end

bot.start
