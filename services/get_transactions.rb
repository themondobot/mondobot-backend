class GetTransactions
  attr_reader :client,
              :params

  def initialize(client, params)
    @client = client
    @params = params
  end

  def execute
    transactions = @client.transactions
    if params[:latitude] && params[:longitude]
      transactions = Mondo::Transaction.search_by_location(transactions, params[:latitude], params[:longitude], 10)
    end
    if params[:date]
      transactions = Mondo::Transaction.search_by_date(transactions, params[:date])
    end
    if params[:merchant_name]
      transactions = Mondo::Transaction.search_by_merchant(transactions, params[:merchant_name])
    end
    transactions
  end
end
