require File.expand_path('../at',  __FILE__)
require File.expand_path('../set', __FILE__)

RSpec.configure do |config|
  [:all, :each].each do |x|
    config.before(x) do
      repository(:default) do |repository|
        transaction = DataMapper::Transaction.new(repository)
        transaction.begin
        repository.adapter.push_transaction(transaction)
      end
    end

    config.after(x) do
      repository(:default).adapter.pop_transaction.rollback
    end
  end

  config.include RSpecExtensions::Set
  config.include RSpecExtensions::At
end
