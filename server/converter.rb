require 'time'
require 'json'

def parse(packet)
  meta_data = packet[3]
  str_date = meta_data.match(/..\/../).to_s
  str_time = meta_data.match(/..:../).to_s

  updated_at = Time.strptime("%s %s"%[str_date, str_time], "%m/%d %H:%M")

  { border_1: packet[0].gsub(',', '').to_i, border_100: packet[1].gsub(',', '').to_i, border_1200: packet[2].gsub(',', '').to_i, updated_at: updated_at }
end

def convert(file_name)
  data_list = []
  open(file_name) do |file|
    buffer = []
    lines = fields = 0
    file.readlines.each do |l|
      lines += 1
      buffer.push(l.gsub(/(\n|\r\n)/, ''))
      if (lines % 4 == 0) then
        data_list.push(parse buffer)
        buffer = []
      end
    end
  end

  JSON.generate(data_list)
end

puts convert("sample.log")
