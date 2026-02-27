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

get '/signin' do
    erb :signin
end

get '/signup' do
    erb :signup
end

post '/signin' do
    user=User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user]=user.id
        return_to=session.delete(:return_to)
        redirect return_to || '/'
    else
        redirect '/signin'
    end
end

post '/signup' do
    @user=User.create(name: params[:name], email: params[:email], password: params[:password], password_confirmation: params['password-confirm'])
    if @user.persisted?
        redirect '/signin'
    else
        redirect '/signup'
    end
end

post '/jokes/:id/fav' do
    if session[:user]
        Fav.create(user_id: session[:user], joke_id: params[id])
        redirect "/jokes/#{params[:id]}"
    else
        session[:return_to]="/jokes/#{params[:id]}"
        redirect '/signin'
    end
end