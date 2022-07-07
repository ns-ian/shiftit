# frozen_string_literal: true

require 'sinatra'
require 'dotenv/load' if development?

require 'json'
require 'net/http'
require 'securerandom'

require_relative 'constants'

get '/' do
  session = env['rack.session']
  session_state = session['state']

  if params['state'] && session_state
    if session_state.include?('first_')
      redirect '/1'
    elsif session_state.include?('second_')
      redirect '/2'
    end
  end

  @client_id = ENV['CLIENT_ID']
  @redirect_uri = ENV['REDIRECT_URI']
  @state = "first_#{SecureRandom.hex(10)}"
  session['state'] = @state
  erb :index
end

get '/1' do
  @client_id = ENV['CLIENT_ID']
  @redirect_uri = ENV['REDIRECT_URI']
  @subscriptions = JSON.generate(list_subs)
  @preferences = JSON.generate(fetch_prefs)
  @state = "second_#{SecureRandom.hex(10)}"
  session['state'] = @state
  erb :a
end

get '/2' do
  erb :b
end

post '/2' do
  body = JSON.parse(request.body.read)
  if body['subscriptions']
    subscribe_all!(body['subscriptions'])
  elsif body['preferences']
    update_prefs!(body['preferences'])
  else
    [400, ['No subscriptions or preferences found in request.']]
  end
end

private

def reddit_oauth
  unless @reddit_oauth
    @reddit_oauth = Net::HTTP.new('oauth.reddit.com', 443)
    @reddit_oauth.use_ssl = true
  end
  @reddit_oauth
end

def get_subs(after = nil, count = nil)
  header = { 'Authorization' => "bearer #{session['token']}" }
  request_string = '/subreddits/mine/subscriber?show=all&raw_json=1'
  request_string += "&after=#{after}" if after
  request_string += "&count=#{count}" if count
  response = reddit_oauth.get(request_string, header.merge(USER_AGENT))
  JSON.parse(response.body)
end

def list_subs(sub_list = [], count = 0, subs = {})
  loop do
    subs = get_subs(subs.dig('data', 'after'), count)
    subs.dig('data', 'children').each do |sub|
      sub_list << sub.dig('data', 'display_name')
      count += 1
    end
    break unless subs.dig('data', 'after')
  end
  sub_list
end

def fetch_prefs
  header = { 'Authorization' => "bearer #{session['token']}" }
  response = reddit_oauth.get('/api/v1/me/prefs', header.merge(USER_AGENT))
  JSON.parse(response.body)
end

def subscribe_all!(subs)
  logger.info("Session token: #{session['token']}")
  header = { 'Authorization' => "bearer #{session['token']}" }
  request_path = '/api/subscribe'
  request_body = "action=sub&action_source=o&sr_name=#{subs}"
  response = reddit_oauth.post(request_path, request_body, header.merge(USER_AGENT))
  logger.info("Response: #{response.body}")
  response.code.to_i
end

def update_prefs!(prefs)
  header = {
    'Authorization' => "bearer #{session['token']}",
    'Content-Type' => 'application/json'
  }
  request_path = '/api/v1/me/prefs'
  response = reddit_oauth.patch(request_path, prefs, header.merge(USER_AGENT))
  response.code.to_i
end
