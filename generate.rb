require 'bundler/setup'
Bundler.require
require 'dotenv/load'
require 'httparty'
require 'json'
require './models'

# --- URL取得部分 ---
begin
  # 保存されたファイルがあるか確認
  if File.exist?('./app_url.txt')
    app_url = File.read('./app_url.txt').strip
  else
    # ファイルがない場合はエラーにするか、あるいは前回のCloudFront URLを
    # 最後の手段として書いておく（念のため）
    app_url = "https://d3t7yrnoci2ji2.cloudfront.net" 
  end
rescue => e
  app_url = "https://d3t7yrnoci2ji2.cloudfront.net"
end

recent_jokes = Joke.order(created_at: :desc).limit(10).pluck(:joke).join("\n")

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
            content: "英語のジョークを1つ作成してください。以下のJSON形式のみで返してください。\n\n以下のジョークはすでに使用済みなので、全く異なるジョークを作成してください。\n#{recent_jokes}\n\n
            ジョークには言葉遊び（pun）やダブルミーニング、スラングなどのフランクな表現が含まれていて構いません。暴力的・性的な表現でない限り、犯罪用語もジョークの文脈で使用可能です。
            key_expは英語の表現・イディオムのみを記載し、日本語や解説は含めないでください。\n{\"joke\": \"英語のジョーク本文\", \"translation\": \"日本語訳\", \"explanation\": \"解説\", \"key_exp\": \"キーとなる英語表現\"}"
        }],
        temperature: 1.0
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
        content: "🃏 今日の英語ジョーク\n\n**#{joke.joke}**\n\n📎 詳細はこちら: #{app_url}/jokes/#{joke.id}"
    }.to_json
)