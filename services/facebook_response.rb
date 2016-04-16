class FacebookResponse
  attr_accessor :recipient, :message

  def initialize(recipient, message: nil)
    self.recipient = recipient
    self.message = message.to_s.downcase
  end

  def responses
    responses = []

    responses << text_response("Hello!") if greeting?
    responses << text_response(":)") if greeting?

    if message.length < 1
      responses << image_response("https://45.media.tumblr.com/cfd039730669f89c064f69e57e0877af/tumblr_nj6ipiNACJ1t8s6eeo1_500.gif")
    end

    responses
  end

  def send!
    responses.each do |response|
      Unirest.post "https://graph.facebook.com/v2.6/me/messages?access_token=#{ENV['PAGE_ACCESS_TOKEN']}",
                   headers: { "Content-Type" => "application/json" },
                   parameters: { recipient: recipient, message: response } do |r|
        puts "SEND #{r.code} -- #{r.body}"
      end
    end
  end

  private

  def text_response(message)
    {
      text: message
    }
  end

  def image_response(url)
    {
      attachment: {
        type: :image,
        payload: {
          url: url
        }
      }
    }
  end

  def greeting?
    ["hello", "hey", "sup", "lo", "hi"].each do |greeting|
      if message.split(/\W+/).include?(greeting)
        return true
      end
    end
    false
  end

  def message_handler
    @handler ||= MessageHandler.new
  end
end
