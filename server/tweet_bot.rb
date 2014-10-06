require 'twitter'

def parse(packet)
  meta_data = packet.pop
  str_date = meta_data.match(/..\/../).to_s
  str_time = meta_data.match(/..:../).to_s

  updated_at = Time.strptime("%s %s"%[str_date, str_time], "%m/%d %H:%M")

  ret = {
    time: updated_at.to_i
  }

  packet.each do |data|
    pac = data.split(':')
    key = 'border_%d'%[pac[0]]
    ret[key.to_sym] = pac[1].gsub(',', '').to_i
  end

  ret[:updated_at] = updated_at

  ret
end

file_name = File.expand_path('recent.tmp', File.dirname(__FILE__))
data = nil
open(file_name) do |f|
  data = parse f.readlines
end

exit if data.nil?

timestamp = data[:updated_at]

tweet = "#{timestamp.month}月#{timestamp.day}日 #{timestamp.hour}時#{timestamp.min}分時点のボーダーは\n"
data.select{|sym| sym.to_s.include? 'border_' }.each do |border, score|
  tweet += "  #{border.to_s.sub('border_', '')}位 #{score.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse}pt\n"
end
tweet += "です。\n"

Twitter::REST::Client.new(
  consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
  consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
  access_token:        ENV['TWITTER_ACCESS_TOKEN'],
  access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET']
) do |bot|
  bot.update tweet
end
