require 'sinatra'
require 'byebug'
require 'json'
require 'unirest'
require 'dotenv'

Dotenv.load

get '/fbwebhooks' do
  # {"hub.mode"=>"subscribe", "hub.challenge"=>"2122262245", "hub.verify_token"=>"wiliness-airy-rind-dumpling-godhood-acreage"}

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
    byebug
    recipient = json["entry"].first["messaging"].first["sender"]
    write_a_message(recipient, "you said #{json["message"]["text"]}")

    status 201
    body ''
  rescue => e
    puts e
    puts ":("
    status 201
    body ''
  end
end


def write_a_message(recipient, message)
  Unirest.post "https://graph.facebook.com/v2.6/me/messages?access_token=#{ENV['PAGE_ACCESS_TOKEN']}",
               headers: { "Content-Type" => "application/json" },
               parameters: { recipient: recipient, message: message }.to_json { |r| }
end



# "{\"object\":\"page\",\"entry\":[{\"id\":561644537351666,\"time\":1460810227387,\"messaging\":[{\"sender\":{\"id\":991948220860527},\"recipient\":{\"id\":561644537351666},\"timestamp\":1460809900096,\"message\":{\"mid\":\"mid.1460809899907:98245008c98cb47b42\",\"seq\":2,\"text\":\"Hi\"}}]}]}"
