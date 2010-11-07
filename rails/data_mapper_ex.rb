module DataMapper
  module Resource
    # This method is noisily deprecated in DataMapper, but used by Formtastic
    def new_record?
      new?
    end

    # Execute the given block inside a transaction with a set isolation
    # level. In test mode, the isolation level is not set, since it has
    # no effect, and breaks with nested transactions used for faster testing.
    #
    # level - :read_uncommitted, :read_committed, :repeatable_read or :serializable
    # block - the code to run inside a transaction
    def isolated_transaction(level = nil, &block)
      transaction do
        if level && !Rails.env.test?
          repository.adapter.execute("SET TRANSACTION ISOLATION LEVEL #{level.to_s.tr('_', ' ')}")
        end

        block.call
      end
    end
  end
end

# By default, all properties are required
DataMapper::Property.required(true)
