class GetBalance
  attr_reader :client

  def initialize(client)
    @client = client
  end

  def execute
    Money.new(@client.balance.balance, @client.balance.currency)
  end
end
