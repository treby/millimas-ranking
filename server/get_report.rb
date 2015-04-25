require 'optparse'
require 'mechanize'

params = ARGV.getopts('s:f:', 'event_id:')
series_name = params['s'] || 'event'
event_id = params['event_id']
log_filename = "#{series_name}.log"
tmp_identify='recent'
html_filename = "#{tmp_identify}.html"
recent_tmp = params['f'] || "#{tmp_identify}.tmp"

def login(agent)
  gree_email = ENV['GREE_EMAIL']
  gree_pass = ENV['GREE_PASSWORD']

  agent.get('http://gree.jp/?action=reg_opt_top') do |page|
    page.form_with(name: 'login') do |login|
      login.field_with(name: 'user_mail') do |email|
        email.value = gree_email
      end
      login.field_with(name: 'user_password') do |pass|
        pass.value = gree_pass
      end
    end.submit
  end
end

def imc_top_lounge(agent, event_id, page_limit = 2)
  lounge_list = []
  lounge_ranking_page = "http://imas.gree-apps.net/app/index.php/event/#{event_id}/ranking/lounge"
  (1..page_limit).each do |page_num|
    agent.get("#{lounge_ranking_page}?page=#{page_num}") do |page|
      page.search('.list-bg > li').each do |li|
        lounge_id = li.search('td').last.search('a').first.attributes['href'].value.split('/').last.to_i
        lounge_name = li.search('td').last.search('a').first.child.text
        lounge_rank = li.search('td').last.text.gsub(/(\t|\s|\n|\r|\f|\v)/,"").match(/(\d+)位/)[1]
        lounge_point = li.search('td').last.text.gsub(/(\t|\s|\n|\r|\f|\v)/,"").split('pt').last.gsub("\u00A0", '').gsub(',', '').to_i
        lounge_list << { rank: lounge_rank, id: lounge_id, name: lounge_name, pt: lounge_point }
      end
    end
  end

  lounge_list
end

agent = Mechanize.new
agent.user_agent_alias = 'iPhone'

login(agent)

target_uri = 'http://imas.gree-apps.net/app/index.php/event'
backurl = URI.encode_www_form({ url: target_uri })

begin
  agent.get(target_uri)
rescue Mechanize::ResponseCodeError => ex
  case ex.response_code
  when '503' then
  end
end

agent.get('http://pf.gree.net/58737?' + backurl) do |page|
  page.form_with(name: 'redirect').submit
end

output = []
agent.get(target_uri)
event_page = agent.page

event_page.save!(html_filename)

event_page.search('.event-user-status').first.text.gsub(/(\t|\s|\n|\r|\f|\v)/,"").gsub(/.pt/,';').split(';').each do |line|
  next unless line.include?('位')
  border = line.strip.sub(/位/, ':')
  output.push border
end

target_elm = nil
event_page.search('.pb').each do |pb_elm|
  target_elm = pb_elm and break if pb_elm.text.include? '集計時点'
end

timestamp = target_elm.text.gsub(/(\t|\s|\n|\r|\f|\v)/,"")

output.push timestamp
File.write(recent_tmp, output.join("\n"))
open(log_filename, 'a+') do |f|
  f.write output.join("\n")
  f.write "\n"
end

# IMCならラウンジランキングも取得する
if series_name.include?('_imc') && !(event_id.nil?)
  rank_list = imc_top_lounge(agent, event_id.to_i)
  open("#{series_name}_lounge.log", 'a+') do |f|
    t = Time.now
    f.write "#{t}\t#{t.to_i}\n"
    rank_list.each do |rank|
      f.write "#{rank[:rank]}\t#{rank[:id]}\t#{rank[:name]}\t#{rank[:pt]}\n"
    end
  end
end
