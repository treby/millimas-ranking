require 'time'
require 'optparse'
require 'influxdb'

params = ARGV.getopts('s:f:')
series_name = 'sample'
series_name = params['s'] unless params['s'].nil?
file_name = series_name
file_name = params['f'] unless params['f'].nil?
res_file_name = File.expand_path("#{file_name}", File.dirname(__FILE__))
host = 'localhost'
user = 'treby'
pass = 'treby'
db_name = 'millimas_ranking'

def parse(packet)
  meta_data = packet.pop
  str_date = meta_data.match(/..\/../).to_s
  str_time = meta_data.match(/..:../).to_s

  updated_at = Time.strptime("%s %s"%[str_date, str_time], "%m/%d %H:%M")

  ret = { time: updated_at.to_i }
  packet.each do |line|
    rank, point = line.split(':')
    ret["border_#{rank}".to_sym] = point.gsub(',', '').to_i
  end
  ret[:updated_at] = updated_at
  ret
end

def convert_and_insert(file_name, host, user, pass, db_name, series_name)
  data_list = []
  influxdb = InfluxDB::Client.new db_name, host: host, username: user, password: pass

  open(file_name) do |file|
    buffer = []
    last_data = {}
    file.readlines.each do |l|
      buffer.push(l.gsub(/(\n|\r\n)/, ''))

      next unless buffer.last.include?('※')

      data = parse buffer
      next if data[:time] == last_data[:time]

      last_data = data

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
