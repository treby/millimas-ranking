require 'twitter'
require 'influxdb'
require 'time'
require 'optparse'

params = ARGV.getopts('s:f:')
series_name = 'sample'
series_name = params['s'] unless params['s'].nil?
host = 'localhost'
user = 'treby'
pass = 'treby'
db_name = 'millimas_ranking'

influxdb = InfluxDB::Client.new db_name, host: host, username: user, password: pass
ret = influxdb.query "SELECT * FROM #{series_name} WHERE time > '#{(Time.new - 60 * 60).utc.strftime("%Y-%m-%d %H:%M:%S")}'"
current_data = ret[series_name].first
past_data = ret[series_name].last

timestamp = Time.at current_data['time']
border_tweet = "#{timestamp.month}月#{timestamp.day}日 #{timestamp.hour}時#{timestamp.min}分時点のボーダーは\n"
velocity_tweet = "#{timestamp.month}月#{timestamp.day}日 #{timestamp.hour}時#{timestamp.min}分時点の大体の時速は\n"
current_data.select{|key| key.include? 'border_' }.sort.each do |border, score|
  order = border.to_s.sub('border_', '')
  border_tweet += "  #{order}位 #{score.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}pt\n"
  velocity_tweet += "  #{order}位 #{(score - past_data[border.to_s]).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}pt/h\n"
end
border_tweet += "です。\n"
velocity_tweet += "です。\n"

Twitter::REST::Client.new(
  consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
  access_token:        ENV['TWITTER_ACCESS_TOKEN'],
  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET']
) do |bot|
  bot.update border_tweet
  bot.update velocity_tweet
end
