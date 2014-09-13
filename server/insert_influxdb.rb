require 'time'
require 'influxdb'

series_name = 'sample'
res_file_name = File.expand_path('%s.log'%[series_name], File.dirname(__FILE__))
host = 'localhost'
user = 'treby'
pass = 'treby'
db_name = 'millimas_ranking'

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

def convert_and_insert(file_name, host, user, pass, db_name, series_name)
  data_list = []
  influxdb = InfluxDB::Client.new db_name, host: host, username: user, password: pass

  open(file_name) do |file|
    buffer = []
    file.readlines.each do |l|
      buffer.push(l.gsub(/(\n|\r\n)/, ''))
      next if buffer.length < 4

      data = parse buffer

      data_list.push(data)
      influxdb.write_point(series_name, data)
      buffer = []
    end
  end

  data_list
end

convert_and_insert(res_file_name, host, user, pass, db_name, series_name).each do |data|
  p data
end
