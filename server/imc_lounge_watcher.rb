require 'twitter'
require 'optparse'

class ImcTopLoungeWatcher
  def initialize
    @build = false
    @logs = []
  end

  def read_logfile(logfilename, chunk_size = 21)
    log_lines = File.open(logfilename).readlines
    log_lines.each_slice(chunk_size) do |chunk|
      time = Time.at(chunk.first.split("\t").last.to_i)
      ranking_info = chunk[1..-1].map { |line| parse_log(line) }
      @logs << { time: time, ranking: ranking_info }
    end

    @build = true
    @logs
  end

  def check_diff(border = 12, current_log = nil, previous_log = nil)
    raise unless build?
    return [] if @logs.count < 2

    @diffs = []
    current = current_log || @logs.last
    previous = previous_log || @logs[-2]

    diff = false
    current[:ranking][0...border].each do |lounge|
      rank = lounge[:rank]
      info = previous[:ranking].select { |t| t[:id] == lounge[:id] }
      previous_rank = info.empty? ? nil : info.first[:rank]
      next if rank == previous_rank

      @diffs << {previous: info.first, current: lounge}
    end

    @diff_updated_at = current[:time]
    @diffs
  end

  def tweet_text
    raise unless build?
    return nil if @diffs.empty?

    time = Time.at(@diff_updated_at)
    tweet = "#{time.strftime('%d日%H:%M')}変動\n"
    @diffs.each_with_index do |diff, i|
      break unless i < 4 # Twitter140文字対策
      current = diff[:current]
      previous = diff[:previous]
      icon = current[:rank] < previous[:rank] ? '↑' : '↓'
      oku = (current[:point] / 100_000_000).floor
      man = ((current[:point] % 100_000_000) / 10_000).floor
      tweet << "#{icon} #{current[:rank]}位 #{oku}億#{man}万pt"
      tweet << "/#{current[:name].gsub('@', '@ ')}"
      tweet << " http://imas.gree-apps.net/app/index.php/lounge/profile/id/#{current[:id]}" unless @diffs.count > 2
      tweet << "\n"
    end

    tweet
  end

  def twitter_update(tweet = nil)
    text = tweet || tweet_text
    return if text.nil?

    Twitter::REST::Client.new(
      consumer_key:        ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret:     ENV['TWITTER_CONSUMER_SECRET'],
      access_token:        ENV['TWITTER_ACCESS_TOKEN'],
      access_token_secret: ENV['TWITTER_ACCESS_TOKEN_SECRET']
    ) do |bot|
      bot.update text
    end
  end

  def build?
    @build
  end

  private
  def parse_log(line)
    arr = line.force_encoding('UTF-8').split("\t")
    { rank: arr.first.to_i, id: arr[1].to_i, name: arr[2], point: arr.last.to_i }
  end
end

params = ARGV.getopts('f:', 'debug')
debug_mode = params['debug']
filename = params['f']

watcher = ImcTopLoungeWatcher.new
logs = watcher.read_logfile(filename)
unless watcher.check_diff.empty?
  if debug_mode
    puts watcher.tweet_text
  else
    watcher.twitter_update
  end
end
