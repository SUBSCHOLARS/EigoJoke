require 'bundler/setup'
Bundler.require
require 'dotenv/load'
require 'httparty'
require 'json'
require './models'

themes = ["テクノロジー", "SNS", "リモートワーク", "サブスク", "AI", "ゲーム", "カフェ", "通勤", "天気", "食べ物", "スポーツ", "映画", "音楽", "旅行", "ペット"]
theme = themes.sample

joke_data_raw = HTTParty.post(
    "https://api.groq.com/openai/v1/chat/completions",
    headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{ENV['GROQ_API_KEY']}"
    },
    body: {
        model: "llama-3.3-70b-versatile",
        messages: [{
            role: "user",
            content: "#{theme}に関連した英語のジョークを1つ作成してください。以下のJSON形式のみで返してください。key_expは英語の表現・イディオムのみを記載し、日本語や解説は含めないでください。\n{\"joke\": \"英語のジョーク本文\", \"translation\": \"日本語訳\", \"explanation\": \"解説\", \"key_exp\": \"キーとなる英語表現\"}"
        }],
        temperature: 0.7
    }.to_json
)

raw_text = joke_data_raw.dig("choices", 0, "message", "content")
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