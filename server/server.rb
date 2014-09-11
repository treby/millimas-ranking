require 'influxdb'
require 'sinatra'
require 'sinatra/namespace'
require 'json'

influxdb = InfluxDB::Client.new 'millimas_ranking', username: 'treby', password: 'treby'

ranking_master = [
  {id: 1, name: 'natsumatsuri_ranking'},
  {id: 2, name: 'imc6_ranking'},
  {id: 3, name: 'noryo_ranking'},
  {id: 4, name: 'gokudou'},
]

set :environment, :production

namespace '/api' do
  get '/fetch/:id' do
    series_name = ranking_master.first[:name]
    ranking_master.each do |record|
      if record[:id].to_s == params[:id] then
        series_name = ranking_master[params[:id].to_i - 1][:name]
        break
      end
    end

    out = influxdb.query 'select * from %s'%[series_name]
    out.to_json
  end
end
