require 'byebug'

class GetTransactions
  attr_reader :facebook_token, :params

  def initialize(facebook_token, params)
    @facebook_token = facebook_token
    @params = params
    execute
  end

  private

  def execute

  end
end
