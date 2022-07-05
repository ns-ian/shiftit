# frozen_string_literal: true

require 'base64'
require 'json'
require 'net/http'

require_relative 'constants'

# Middleware for making Reddit authorization more automatic
class RedditApiHelper
  attr_reader :app, :reddit
  attr_accessor :token

  def initialize(app)
    @app = app
    @reddit = Net::HTTP.new('www.reddit.com', 443)
    reddit.use_ssl = true
  end

  def call(env)
    request = Rack::Request.new(env)
    session = env['rack.session']
    code = request.GET['code']
    state = request.GET['state']

    session['token'] = request_token(code) if code && state && state == session['state']
    app.call env
  end

  def request_token(code)
    header = { 'Authorization' => "basic #{Base64.strict_encode64("#{CLIENT_ID}:#{SECRET}")}" }
    response = reddit.post(
      '/api/v1/access_token',
      "grant_type=authorization_code&code=#{code}&redirect_uri=#{REDIRECT_URI}",
      header.merge(USER_AGENT)
    )

    parsed_body = JSON.parse(response.body)
    parsed_body['access_token']
  end
end
