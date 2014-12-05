require 'optparse'
require 'mechanize'

params = ARGV.getopts('s:')
series_name = 'event'
series_name = params['s'] unless params['s'].nil?
log_filename = "#{series_name}.log"
html_filename = 'recent.html'
recent_tmp = 'recent.tmp'

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
  target_elm = pb_elm if pb_elm.text.include? '集計時点'
end

event_page.search('.txt').each do |txt_elm|
  target_elm = txt_elm if txt_elm.text.include? '集計時点'
end if target_elm.nil?

timestamp = target_elm.text.gsub(/(\t|\s|\n|\r|\f|\v)/,"")

output.push timestamp
File.write(recent_tmp, output.join("\n"))
open(log_filename, 'a+') do |f|
  f.write output.join("\n")
  f.write "\n"
end
