require 'mechanize'
require 'nokogiri'
require 'uri'

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

target_uri = 'http://imas.gree-apps.net/app/index.php'
backurl = URI.encode_www_form({ url: target_uri })
event_uri = 'http://imas.gree-apps.net/app/index.php/event'

begin
  agent.get(target_uri)
rescue Mechanize::ResponseCodeError => ex
  case ex.response_code
  when '503' then
    p agent.page
  end
end

agent.get('http://pf.gree.net/58737?' + backurl) do |page|
  page.form_with(name: 'redirect').submit
end

agent.get(event_uri)
agent.page.search('.event-user-status').text.gsub(/(\t|\s|\n|\r|\f|\v)/,"").gsub(/.pt/,';').split(';').slice(0..2).each do |line|
  puts line.split(/位/)[1]
end

puts agent.page.search('.s-pt')[1].text.gsub(/(\t|\s|\n|\r|\f|\v)/,"")
