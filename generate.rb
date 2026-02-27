require 'bundler/setup'
Bundler.require
require 'dotenv/load'
require 'httparty'
require 'json'
require './models'

joke_data_raw = HTTParty.post(
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

raw_text = joke_data_raw.dig("candidates", 0, "content", "parts", 0, "text")
cleaned_text = raw_text.gsub(/```json\n/, '').gsub(/\n```/, '')
joke_data = JSON.parse(cleaned_text)

joke = Joke.create(
    joke: joke_data["joke"],
    translation: joke_data["translation"],
    explanation: joke_data["explanation"],
    key_exp: joke_data["key_exp"]
)

HTTParty.post(
    ENV['DISCORD_WEBHOOK_URL'],
    headers: {'Content-Type' => 'application/json'},
    body: {
        content: "🃏 今日の英語ジョーク\n\n**#{joke.joke}**\n\n📎 詳細はこちら: http://あなたのURL/jokes/#{joke.id}"
    }.to_json
)