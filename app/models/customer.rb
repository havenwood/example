class Customer
  include ActiveModel::AttributeMethods
  include ActiveModel::Dirty
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  extend Enumerable

  API = Square.new.customers

  TRAITS = %i[id creation_source groups preferences created_at updated_at]
  FIELDS = %i[given_name family_name company_name nickname email_address address
              phone_number reference_id note birthday idempotency_key]
  ATTRIBUTES = TRAITS + FIELDS

  attr_accessor :persisted

  attr_reader *ATTRIBUTES
  attr_writer *TRAITS

  FIELDS.each do |field|
    define_method "#{field}=" do |value|
      public_send "#{field}_will_change!"
      instance_variable_set "@#{field}", value
    end
  end

  define_attribute_methods *ATTRIBUTES

  def initialize(attributes = {})
    yield self if block_given?
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

    def create(attributes = OpenStruct.new)
      yield attributes if block_given?
      API.create idempotency_key: SecureRandom.uuid, **attributes.to_h.symbolize_keys
    end

    def update(id, attributes)
      API.update customer_id: id, **attributes.to_h.symbolize_keys
    end

    def delete(id)
      API.delete customer_id: id
    end
    alias destroy delete

    def each
      Customer.list.lazy.flat_map(&:to_a).each do |customer|
        yield Customer.find customer[:id]
      end
    end
  end

  def update(attributes)
    response = self.class.update @id, attributes
    raise response.errors.inspect if response.error?

    self.attributes = response.to_h
    changes_applied

    self
  end

  def delete
    response = self.class.delete @id
    raise response.errors.inspect if response.error?

    self
  end
  alias destroy delete

  def save
    # Update
    if @persisted
      return begin
        update changes.transform_values(&:last)
      rescue
      end
    end

    # Create
    response = self.class.create attributes
    return false if response.error?

    @persisted = true
    self.attributes = response.to_h
    changes_applied

    self
  end

  def save!
    # Update
    return update changes.transform_values(&:last) if @persisted

    # Create
    response = self.class.create attributes
    raise response.errors.inspect if response.error?

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

  def pretty_print(pp)
    pp.object_address_group self do
      pp.breakable

      pp.text "id=#{id.inspect}"
      pp.comma_breakable

      attrs = FIELDS.flat_map do |field|
        pp.text "#{field}=#{public_send(field).inspect}"
        pp.comma_breakable
      end

      pp.text "created_at=#{created_at.inspect}"
      pp.comma_breakable
      pp.text "updated_at=#{updated_at.inspect}"
    end
  end
end
