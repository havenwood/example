class Customer
  include ActiveModel::AttributeMethods
  include ActiveModel::Dirty
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON

  API = Square.new.customers

  TRAITS = %i[id creation_source groups preferences created_at updated_at]
  FIELDS = %i[idempotency_key given_name family_name company_name nickname
              email_address address phone_number reference_id note birthday]
  ATTRIBUTES = TRAITS + FIELDS

  define_attribute_methods *ATTRIBUTES

  attr_reader *ATTRIBUTES
  attr_accessor :persisted

  def initialize(attributes = {})
    @persisted = false
    super
  end

  class << self
    def find(id)
      new(API.retrieve(customer_id: id).to_h).tap do |customer|
        customer.persisted = true
        customer.changes_applied
      end
    end

    def list
      @list ||= API.list
    end

    def create(attributes)
      API.create idempotency_key: SecureRandom.uuid, **attributes.to_h.symbolize_keys
    end

    def update(id, attributes)
      API.update customer_id: id, **attributes.to_h.symbolize_keys
    end

    def delete(id)
      API.delete customer_id: id
    end
    alias destroy delete
  end

  ATTRIBUTES.each do |field|
    define_method "#{field}=" do |value|
      public_send "#{field}_will_change!"
      instance_variable_set "@#{field}", value
    end
  end

  def update(attributes)
    response = self.class.update @id, attributes
    return response.errors if response.error?

    self.attributes = response.to_h
    changes_applied

    self
  end

  def delete
    response = self.class.delete @id
    return response.errors if response.error?

    self
  end
  alias destroy delete

  def save
    # Update
    return update changes.transform_values(&:last) if @persisted

    # Create
    response = self.class.create attributes
    return response.errors if response.error?

    @persisted = true
    self.attributes = response.to_h
    changes_applied

    self
  end

  def persisted?
    @persisted
  end

  def attributes
    ATTRIBUTES.to_h { |key| [key.to_s, public_send(key)] }.compact
  end
end
