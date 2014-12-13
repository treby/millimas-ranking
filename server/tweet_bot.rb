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

velocity_enabled = false

params = ARGV.getopts('s:f:')
series_name = params['s']
series_name ||= 'sample'
host = 'localhost'
user = 'treby'
pass = 'treby'
db_name = 'millimas_ranking'

influxdb = InfluxDB::Client.new db_name, host: host, username: user, password: pass
time_to_get = Time.new - 60 * 3 # 3 minutes ago

ret = influxdb.query "SELECT * FROM #{series_name} WHERE time > '#{time_format(time_to_get - 60 * 60)}' AND time < '#{time_format(time_to_get + 60)}'"
current_data = ret[series_name].first
past_data = ret[series_name].last

border_list = {}
current_data.select{|key| key.include? 'border_' }.sort{|a, b| border_number(a.first) <=> border_number(b.first)}.each do |border, score|
  if velocity_enabled
    border_list[border_number(border).to_s] = { point: score, velocity: (score - past_data[border]) } unless past_data[border].nil?
  else
    border_list[border_number(border).to_s] = { point: score }
  end
end

timestamp = Time.at current_data['time']
border_txt = velocity_txt = tweet_txt = "☆#{timestamp.strftime('%m/%d %H:%M')}時点"
border_txt += "のボーダーは\n"
velocity_txt += "のボーダー時速は\n"
tweet_txt += "\n"

border_list.each do |rank, border|
  # Borders
  tweet_txt += "　#{rank}位 #{number_format border[:point]}pt"
  border_txt += "　#{rank}位 #{number_format border[:point]}pt\n"

  # Velocities
  if velocity_enabled
    tweet_txt += "(+#{number_format border[:velocity]})"
    velocity_txt += "　#{rank}位 #{number_format border[:velocity]}pt/h\n"
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
