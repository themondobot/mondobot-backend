require 'unirest'

class FacebookResponse
  attr_accessor :recipient, :message

  TEST_IMAGE = "https://45.media.tumblr.com/cfd039730669f89c064f69e57e0877af/tumblr_nj6ipiNACJ1t8s6eeo1_500.gif"

  def initialize(recipient, message: nil)
    self.recipient = recipient
    self.message = message.to_s.downcase
  end

  def responses
    responses = []

    responses << text_response("Hello!") if greeting?
    responses << text_response(":)") if greeting?

    if transaction_params = get_transaction_details
      transactions = GetTransactions.new(get_client, transaction_params).execute
      responses << format_transactions(transactions)
    end

    if get_balance?
      balance = GetBalance.new(get_client).execute
      responses << text_response("Your balance is #{balance.format}")
    end

    if message.length < 1
      responses << image_response(TEST_IMAGE)
    end

    if unauthorized?
      puts "UNAUTHROZIED"
      responses << link_to_mondo_auth
    else
      puts "authed!"
    end

    responses
  end

  def send!
    responses.each do |response|
      payload = { recipient: recipient, message: response }

      puts "---------sending payload"
      puts payload
      puts "---------"

      Unirest.post "https://graph.facebook.com/v2.6/me/messages?access_token=#{ENV['PAGE_ACCESS_TOKEN']}",
                   headers: { "Content-Type" => "application/json" },
                   parameters: payload.to_json do |r|
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

  def button_response(title, buttons=[])
    {
      attachment: {
        type: :template,
        payload: {
          template_type: :button,
          text: title,
          buttons: buttons
        }
      }
    }
  end

  def format_transactions(transactions)
    transaction_tiles = []
    transactions.each do |transaction|
      element = {
        title: transaction.merchant.try(:name) || transaction.description,
        subtitle: transaction.amount.format,
        image: transaction.merchant.try(:logo) || 'https://getmondo.co.uk/static/images/mondo-mark-01.png'
      }
      transaction_tiles << create_element_for_list(element)
    end
    format_elements transaction_tiles
  end

  def create_element_for_list(element)
    tile = {
      title: element[:title],
      subtitle: element[:subtitle]
    }
    tile[:image_url] = element[:image] if element[:image]
    tile[:buttons] if element[:buttons].to_a
    element[:buttons].to_a.each do |button|
      tile[:buttons] << {
          type: :web_url,
          url: button.url,
          title: button.title
        }
    end
    tile
  end

  def format_elements(elements)
    {
      attachment: {
        type: :template,
        payload: {
          template_type: :generic,
          # text: message,
          elements: elements
        }
      }
    }
  end

  def link_to_mondo_auth
    url = [
      "#{ENV['MONDO_AUTH_URL']}/?",
      "client_id=#{ENV['MONDO_CLIENT_ID']}&",
      "redirect_uri=#{ENV['HOST']}/mondo_callback&",
      "response_type=code&"
    ].join("")

    button_response(
      "You need to authorize with Mondo so I can access your account!",
      [
        {
          type: :web_url,
          title: "Authorize",
          url: url
        }
      ]
    )
  end

  def unauthorized?
    !authorized?
  end

  def authorized?
    user = User.find_by(facebook_token: facebook_token)
    return false unless user.present?
    user.mondo_token.present?
  end

  def facebook_token
    recipient["id"]
  end

  def test?
    message.split(/\W+/).include?("test")
  end

  def greeting?
    ["hello", "hey", "sup", "lo", "hi"].each do |greeting|
      if message.split(/\W+/).include?(greeting)
        return true
      end
    end
    false
  end

  def get_transaction_details
    return false unless message.include? "transactions"
    params = {}
    params[:date] = Date.yesterday if message.include? "yesterday"
    params[:date] = Date.today if message.include? "today"
    params
  end

  def get_balance?
    message.include? "balance"
  end

  def message_handler
    @handler ||= MessageHandler.new
  end

  def get_client
    return @client if @client
    token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjaSI6Im9hdXRoY2xpZW50XzAwMDA5NFB2SU5ER3pUM2s2dHo4anAiLCJleHAiOjE0NjEwMDk3NTcsImlhdCI6MTQ2MDgzNjk1NywianRpIjoidG9rXzAwMDA5N0djTldoUmRmN0NBZUFvbWYiLCJ1aSI6InVzZXJfMDAwMDk3RnBKcTE0eXhsdTdJMkRiZCIsInYiOiI0In0.HVkL8v5UHn8Ymn6YCNSwEqQJbrIxScAsZXqYeQwLm64"
    account_id = "acc_000097FqTUdHRQwns220cz"
    @client = Mondo::Client.new(token: token, account_id: account_id)
    @client.api_url = "https://staging-api.gmon.io"
    @client
  end
end
