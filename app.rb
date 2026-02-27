require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require "./models.rb"

require 'dotenv/load'

require 'httparty'
require 'json'

require 'cloudinary'

enable :sessions

before do
    Dotenv.load
end

get '/' do
    @jokes=Joke.all.order(created_at: :desc)
    erb :index
end

get '/jokes/:id' do
    @joke=Joke.find(params[:id])
    erb :joke_show
end