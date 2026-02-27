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

def generate_joke
    response=HTTParty.post(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{ENV['GEMINI_API_KEY']}",
        headers: {'Content-Type' => 'application/json'},
        body: {
            contents: [{
                parts: [{
                    text: "英語のジョークを1つ作成してください。以下のJSON形式のみで返してください。\n{\"joke\": \"英語のジョーク本文\", \"translation\": \"日本語訳\", \"explanation\": \"解説\", \"key_exp\": \"キーとなる英語表現\"}"
                }]
            }]
        }.to_json
    )
    raw_text=response.dig("candidates", 0, "content", "parts", 0, "text")
    cleaned_text=raw_text.gsub(/```json\n/, '').gsub(/\n```/, '')
    JSON.parse(cleaned_text)
end

get '/' do
    joke_data = generate_joke
    joke_data.to_s
end

get '/test' do
  joke_data = generate_joke
  joke_data.to_s
end