class Customer
  include ActiveModel::AttributeAssignment
  include ActiveModel::Attributes
  include ActiveModel::Conversion
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations

  extend ActiveModel::Naming
  extend ActiveModel::Translation
  extend ActiveSupport::Concern
  extend Enumerable

  API = Square.new.customers

  TRAITS = %i[id creation_source groups preferences created_at updated_at]
  FIELDS = %i[given_name family_name company_name nickname email_address address
              phone_number reference_id note birthday idempotency_key]
  ATTRIBUTES = TRAITS + FIELDS

  attribute :id, :string
  attribute :creation_source, :string
  attribute :groups
  attribute :preferences
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  FIELDS.each do |field|
    attribute field, :string
  end

  attr_accessor :persisted

  FIELDS.each do |field|
    define_method "#{field}=" do |value|
      public_send "#{field}_will_change!"
      super(value)
    end
  end

  attribute_method_suffix '?'

  define_attribute_methods *FIELDS

  def attribute?(attr)
    public_send(attr).present?
  end

  def initialize(attributes = {})
    super()

    @persisted = false
    assign_attributes(attributes) if attributes
    yield self if block_given?
  end

  class << self
    def find(id)
      customer = API.retrieve customer_id: id
      raise KeyError, "no customer found for id `#{id}'" unless customer.success?

      new(customer.to_h).tap do |customer|
        customer.persisted = true
        customer.changes_applied
      end
    end

    def list
      @list ||= API.list
    end

    def paginate(page:, per_page: 25)
      list.paginate(page: page, per_page: per_page).map do |customer|
        Customer.new customer
      end
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
    response = self.class.update id, attributes
    raise response.errors.inspect if response.error?

    self.attributes = response.to_h
    changes_applied

    self
  end

  def delete
    response = self.class.delete id
    raise response.errors.inspect if response.error?

    @persisted = false

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
    response = self.class.create changes.transform_values(&:last)
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
    response = self.class.create changes.transform_values(&:last)
    raise response.errors.inspect if response.error?

    @persisted = true
    self.attributes = response.to_h
    changes_applied

    self
  end

  def persisted?
    @persisted
  end

  def pretty_print(pp)
    pp.object_address_group self do
      pp.breakable

      attributes.symbolize_keys.slice(*Customer::TRAITS).each do |field, value|
        pp.text "#{field}: #{value.inspect}"
        pp.comma_breakable
      end

      *head, tail = attributes.symbolize_keys.slice(*Customer::FIELDS).to_a

      head.each do |field, value|
        pp.text "#{field}=#{value.inspect}"
        pp.comma_breakable
      end

      pp.text "#{tail.first}=#{tail.last.inspect}"
    end
  end

  def inspect
    attrs = attributes.map { |field, value| "#{field}: #{value.inspect}" }.join(', ')

    "#<#{self.class}:#{sprintf "%#018x", object_id << 1} #{attrs}>"
  end
end
