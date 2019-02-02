class Customer
  API = Square.new.customers
  FIELDS = %i[idempotency_key given_name family_name company_name nickname
              email_address address phone_number reference_id note birthday]
  TRAITS = %i[id creation_source groups preferences created_at updated_at]
  Attributes = Struct.new *FIELDS, *TRAITS, keyword_init: true

  include ActiveModel::Model
  extend Forwardable

  attr_accessor :id
  attr_accessor :attributes

  def initialize(attributes = {})
    super
    @attributes = Attributes.new
  end

  class << self
    def find(id)
      customer = new id: id
      customer.attributes = Attributes.new Customer::API.retrieve(customer_id: id).to_h
      customer
    end

    def list
      @list ||= Customer::API.list
    end

    def delete(id)
      API.delete customer_id: id
    end
    alias destroy delete
  end

  def delete
    API.delete customer_id: @id
  end
  alias destroy delete

  def_delegators 'Customer::API', :create, :update
  def_delegators :@attributes, *FIELDS, *TRAITS

  def persisted?
    @attributes.any?
  end
end
