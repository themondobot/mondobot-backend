class GetBalance
  attr_reader :client

  def initialize(client)
    @client = client
  end

  def execute
    @client.balance
  end
end
