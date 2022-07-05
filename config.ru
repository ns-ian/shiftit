# frozen_string_literal: true

require './app'
require './reddit_api_helper'

use Rack::Session::Cookie,
  :secret => ENV['COOKIE_SECRET']
use RedditApiHelper
run Sinatra::Application
