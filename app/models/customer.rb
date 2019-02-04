class Customer
  include ActiveModel::Model
  extend Forwardable

  API = Square.new.customers

  FIELDS = %i[id idempotency_key given_name family_name company_name nickname
              email_address address phone_number reference_id note birthday]
  TRAITS = %i[creation_source groups preferences created_at updated_at]

  attr_accessor *FIELDS, *TRAITS

  class << self
    def find(id)
      new API.retrieve(customer_id: id).to_h
    end

    def list
      @list ||= API.list
    end

    def create(attributes)
      API.create idempotency_key: SecureRandom.uuid, **attributes
    end

    def update(id, attributes)
      API.update customer_id: id, **attributes
    end

    def delete(id)
      API.delete customer_id: id
    end
    alias destroy delete
  end

  def update(attributes)
    API.update customer_id: @id, **attributes
  end

  def delete
    API.delete customer_id: @id
  end
  alias destroy delete

  def persisted?
    # TODO: Actually relect whether this is persisted.
    true
  end
end
