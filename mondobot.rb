require 'require_all'
require 'sinatra'
require 'pry'
require 'json'
require 'dotenv'
require 'json'
require 'sinatra/activerecord'
require './environments'
require_all './models'
require_all './services'

Dotenv.load

get '/fbwebhooks' do
  if request.params['hub.verify_token'] == ENV['FB_VERIFY_TOKEN']
    request.params['hub.challenge']
  else
    "Error, wrong validation token"
  end
end

get "/users" do
  content_type :json
  @users = User.all
  @users.to_json
end

post '/fbwebhooks' do
  begin
    puts request.body.read
    request.body.rewind
    json = JSON.parse(request.body.read)

    json["entry"].each do |entry|
      entry["messaging"].each do |message|
        recipient = message["sender"]
        message_text = message["message"]["text"]

        FacebookResponse.new(recipient, message: message_text).send!
      end
    end

    status 201
    body ''
  end
end
