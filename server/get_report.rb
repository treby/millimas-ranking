require 'mechanize'

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
agent.page.save!('recent.html')

agent.page.search('.event-user-status').first.text.gsub(/(\t|\s|\n|\r|\f|\v)/,"").gsub(/.pt/,';').split(';').each do |line|
  next unless line.include?('位')
  border = line.strip.sub(/位/, ':')
  puts border

  output.push border
end

timestamp = agent.page.search('.pb')[3].text.gsub(/(\t|\s|\n|\r|\f|\v)/,"")
puts timestamp

output.push timestamp
File.write('recent.tmp', output.join("\n"))
