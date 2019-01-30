class Customer
  extend ActiveModel::Naming

  SQUARE = Square.new

  def self.list
    @list ||= SQUARE.customers.list
  end

  def self.retrieve customer_id:
    SQUARE.customers.retrieve customer_id: customer_id
  end

  def persisted?
    false
  end
end
