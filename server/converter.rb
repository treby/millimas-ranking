require 'time'
require 'redis'
require 'json'

res_file_name = 'sample.log'

def parse(packet)
  meta_data = packet[3]
  str_date = meta_data.match(/..\/../).to_s
  str_time = meta_data.match(/..:../).to_s

  updated_at = Time.strptime("%s %s"%[str_date, str_time], "%m/%d %H:%M")

  {
    time: updated_at.to_i,
    border_1: packet[0].gsub(',', '').to_i,
    border_100: packet[1].gsub(',', '').to_i,
    border_1200: packet[2].gsub(',', '').to_i,
    updated_at: updated_at
  }
end

def convert_from(file_name)
  data_list = []
  redis = Redis.new

  open(file_name) do |file|
    buffer = []
    file.readlines.each do |l|
      buffer.push(l.gsub(/(\n|\r\n)/, ''))
      next if buffer.length < 4

      data = parse buffer

      data_list.push(data)
      redis.zadd('millimas-ranking', data[:time], JSON.generate(data))
      buffer = []
    end
  end

  data_list
end

convert_from(res_file_name).each do |data|
  p data
end
