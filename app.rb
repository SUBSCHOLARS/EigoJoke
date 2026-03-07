require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require "./models.rb"

require 'dotenv/load'

require 'httparty'
require 'json'

require 'cloudinary'

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new

enable :sessions

scheduler.cron '0 9 * * *', timezone: 'Asia/Tokyo' do
    load './generate.rb'
end

get '/admin/generate' do
    load './generate.rb'
    "ジョーク生成完了"
end

get '/admin/env' do
    "APP_URL: #{ENV['APP_URL']}"
end

before do
    Dotenv.load
end

def score_answer(joke, user_answer)
    response=HTTParty.post(
        "https://api.groq.com/openai/v1/chat/completions",
        headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{ENV['GROQ_API_KEY']}"
        },
        body: {
            model: "llama-3.3-70b-versatile",
            messages: [{
                role: "user",
                content: "英語ジョーク: \"\n模範訳: \"#{joke.translation}\"\nユーザーの訳: \"#{user_answer}\"\n\n上記を元にユーザーの訳を100点満点で採点し、以下のJSON形式のみで返してください。\n{\"score\": 85, \"comment\": \"採点コメント\"}"
            }],
            temperature: 0.3
        }.to_json
    )
    raw_text=response.dig("choices", 0, "message", "content")
    cleaned_text=raw_text.gsub(/```json\n/, '').gsub(/\n```/, '')
    JSON.parse(cleaned_text)
end

get '/' do
    @jokes=Joke.all.order(created_at: :desc)
    erb :index
end

get '/jokes/:id' do
    @joke=Joke.find(params[:id])
    if session[:user]
        @answer=Answer.find_by(user_id: session[:user], joke_id: params[:id])
    end
    erb :joke_show
end

post '/jokes/:id/answer' do
    if session[:user]
        joke=Joke.find(params[:id])
        result=score_answer(joke, params[:body])
        
        answer=Answer.find_or_initialize_by(user_id: session[:user], joke_id: params[:id])
        answer.update(
            body: params[:body],
            score: result["score"],
            comment: result["comment"]
        )
        redirect "/jokes/#{params[:id]}"
    else
        session[:return_to]="/jokes/#{params[:id]}"
        redirect '/signin'
    end
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
        existing = Fav.find_by(user_id: session[:user], joke_id: params[:id])
        unless existing
            Fav.create(user_id: session[:user], joke_id: params[:id])
        end
        redirect "/jokes/#{params[:id]}"
    else
        session[:return_to]="/jokes/#{params[:id]}"
        redirect '/signin'
    end
end

get '/users/:id' do
    @user=User.find(params[:id])
    @faved_jokes=@user.faved_jokes
    erb :user_show
end

get '/users/:user_id/collection/:joke_id' do
    @user=User.find(params[:user_id])
    @faved_jokes=@user.faved_jokes.distinct
    @current_joke=Joke.find(params[:joke_id])
    @current_index=@faved_jokes.index(@current_joke)
    @prev_joke=@faved_jokes[@current_index-1] if @current_index > 0
    @next_joke=@faved_jokes[@current_index+1] if @current_index < @faved_jokes.length - 1
    erb :collection
end

get '/signout' do
    session.clear
    redirect '/'
end