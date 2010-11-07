# Hacks to get nested transactions in Postgres
# Not extensively tested, more a proof of concept
#
# It re-opens the existing Transaction class to add a check for whether
# we need a nested transaction or not, and adds a new NestedTransaction
# transaction primitive that issues savepoint commands rather than begin/commit.

module DataMapper
  module Resource
    def transaction(&block)
      self.class.transaction(&block)
    end
  end

  class Transaction
    # Overridden to allow nested transactions
    def connect_adapter(adapter)
      if @transaction_primitives.key?(adapter)
        raise "Already a primitive for adapter #{adapter}"
      end

      primitive = if adapter.current_transaction
        adapter.nested_transaction_primitive
      else
        adapter.transaction_primitive
      end

      @transaction_primitives[adapter] = validate_primitive(primitive)
    end
  end

  module NestedTransactions
    def nested_transaction_primitive
      DataObjects::NestedTransaction.create_for_uri(normalized_uri, current_connection)
    end
  end

  class NestedTransactionConfig < Rails::Railtie
    config.after_initialize do
      repository.adapter.extend(DataMapper::NestedTransactions)
    end
  end
end

module DataObjects
  class NestedTransaction < Transaction

    # The host name. Note, this relies on the host name being configured
    # and resolvable using DNS
    HOST = "#{Socket::gethostbyname(Socket::gethostname)[0]}" rescue "localhost"
    @@counter = 0

    # The connection object for this transaction - must have already had
    # a transaction begun on it
    attr_reader :connection
    # A unique ID for this transaction
    attr_reader :id

    def self.create_for_uri(uri, connection)
      uri = uri.is_a?(String) ? URI::parse(uri) : uri
      DataObjects::NestedTransaction.new(uri, connection)
    end

    #
    # Creates a NestedTransaction bound to an existing connection
    #
    def initialize(uri, connection)
      @connection = connection
      @id = Digest::SHA256.hexdigest(
        "#{HOST}:#{$$}:#{Time.now.to_f}:nested:#{@@counter += 1}")[0..-2]
    end

    def close
    end

    def begin
      run %{SAVEPOINT "#{@id}"}
    end

    def commit
      run %{RELEASE SAVEPOINT "#{@id}"}
    end

    def rollback
      run %{ROLLBACK TO SAVEPOINT "#{@id}"}
    end

    private
    def run(cmd)
      connection.create_command(cmd).execute_non_query
    end
  end
end
