require 'sinatra'
require 'pry'
require 'json'
require 'unirest'
require 'dotenv'

Dotenv.load

get '/fbwebhooks' do
  if request.params['hub.verify_token'] == ENV['FB_VERIFY_TOKEN']
    request.params['hub.challenge']
  else
    "Error, wrong validation token"
  end
end

post '/fbwebhooks' do
  begin
    puts request.body.read
    request.body.rewind
    json = JSON.parse(request.body.read)

    json["entry"].each do |entry|
      entry["messaging"].each do |message|
        recipient = message["sender"]
        write_a_message(recipient, "you said #{message["message"]["text"]}")
      end
    end

    status 201
    body ''
  end
end

def write_a_message(recipient, message)
  Unirest.post "https://graph.facebook.com/v2.6/me/messages?access_token=#{ENV['PAGE_ACCESS_TOKEN']}",
               headers: { "Content-Type" => "application/json" },
               parameters: { recipient: recipient, message: { text: message } } { |r| }
end
