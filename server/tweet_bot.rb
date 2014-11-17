require 'twitter'
require 'influxdb'
require 'time'
require 'optparse'

def number_format(number)
  number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
end

def time_format(time)
  time.utc.strftime("%Y-%m-%d %H:%M:%S")
end

params = ARGV.getopts('s:f:')
series_name = 'sample'
series_name = params['s'] unless params['s'].nil?
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
current_data.select{|key| key.include? 'border_' }.sort.each do |border, score|
  border_list[border.sub('border_', '')] = { point: score, velocity: (score - past_data[border]) }
end

timestamp = Time.at current_data['time']
tweet_txt = "⭐️#{timestamp.month}/#{timestamp.day} #{timestamp.hour}:#{timestamp.min}時点\n"
border_list.each do |rank, border|
  tweet_txt += "　#{rank}位 #{number_format border[:point]}pt"
  tweet_txt += "(+#{number_format border[:velocity]})" unless border[:velocity].nil?
  tweet_txt += "\n"
end

Twitter::REST::Client.new(
  consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
  access_token:        ENV['TWITTER_ACCESS_TOKEN'],
  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET']
) do |bot|
  bot.update tweet_txt
end
