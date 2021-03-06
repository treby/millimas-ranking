require 'twitter'
require 'influxdb'
require 'time'
require 'optparse'

def number_format(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
end

def border_number(border_text)
  border_text.sub('border_', '').to_i
end

def time_format(time)
  time.utc.strftime("%Y-%m-%d %H:%M:%S")
end

def imc_lounge_border_tweet(logfile_name)
  ranking_arr = File.open(logfile_name).readlines
  current_info = ranking_arr[-21..-1]
  time = Time.at(current_info.first.split("\t").last.to_i)
  lounges = current_info[1..-1]
  lounge_list = lounges.map { |l| l.force_encoding('UTF-8').split("\t") }
  lounge = lounge_list.select { |lounge| lounge.first.to_i == 11 }.first
  point = lounge.last.gsub('pt', '').to_i
  "#{time.strftime('%d日%H:%M')}時点のラウンジ11位ボーダーは\n#{number_format(point)}ptです。"
end

velocity_enabled = true

params = ARGV.getopts('s:f:', 'debug')
debug_mode = params['debug']
series_name = params['s']
series_name ||= 'sample'
host = 'localhost'
user = 'treby'
pass = 'treby'
db_name = 'millimas_ranking'

influxdb = InfluxDB::Client.new db_name, host: host, username: user, password: pass
duration = 60 * 60 # An hour as default
time_to_get = Time.new # for debug : Time.parse('2014-12-14 00:00:00')
time_from = time_to_get - duration * 2

ret = influxdb.query "SELECT * FROM #{series_name} WHERE time < '#{time_format(time_to_get + 1)}' AND time > '#{time_format(time_from)}'"
current_data = ret[series_name].first
current_time = Time.at current_data['time']
past_data = ret[series_name].last

ret[series_name].reverse.each do |data|
  break if data['time'] > (current_data['time'] - duration)
  past_data = data
end

border_list = {}
current_data.select{|key| key.include? 'border_' }.sort{|a, b| border_number(a.first) <=> border_number(b.first)}.each do |border, score|
  next if score.nil?
  if velocity_enabled
    border_list[border_number(border).to_s] = { point: score, velocity: (score - past_data[border]) } unless past_data[border].nil?
  else
    border_list[border_number(border).to_s] = { point: score }
  end
end

tweet_txt = "#{current_time.strftime('%m/%d %H:%M')}時点"
border_txt = velocity_txt = "#{current_time.strftime('%m/%d %H:%M')}時点"
border_txt += "のボーダー\n"
velocity_txt += "の時速\n"

border_list.each do |rank, border|
  # Borders
  tweet_txt += "#{rank}位 #{number_format border[:point]}pt"
  border_txt += "#{rank}位 #{number_format border[:point]}pt\n"

  # Velocities
  if velocity_enabled
    tweet_txt += "(+#{number_format border[:velocity]})"
    velocity_txt += "#{rank}位 #{number_format border[:velocity]}pt/h\n"
  end

  tweet_txt += "\n"
end

tweet_list = []

if tweet_txt.length > 140
  tweet_list.push border_txt
  tweet_list.push velocity_txt if velocity_enabled
else
  tweet_list.push tweet_txt
end
tweet_list.push imc_lounge_border_tweet("#{series_name}_lounge.log") if series_name.include? '_imc'

if debug_mode
  tweet_list.each do |tweet|
    puts tweet
  end
  exit
end

Twitter::REST::Client.new(
  consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
  access_token:        ENV['TWITTER_ACCESS_TOKEN'],
  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET']
) do |bot|
  tweet_list.each do |tweet|
    bot.update tweet
  end
end
