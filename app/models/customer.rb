class Customer
  include ActiveModel::Attributes
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON
  include ActiveModel::Model

  extend Enumerable

  API = Square::Client.new(access_token: ENV['SQUARE_TOKEN']).customers

  TRAITS = %i[id creation_source groups preferences created_at updated_at]
  FIELDS = %i[given_name family_name company_name nickname email_address address
              phone_number reference_id note birthday idempotency_key]
  ATTRIBUTES = TRAITS + FIELDS

  attribute :id, :string
  attribute :creation_source, :string
  attribute :groups, :array_of_hashes, default: []
  attribute :preferences, :hash, default: {}
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
  attribute :birthday, :datetime
  attribute :address, :hash, default: {}

  (FIELDS - %i[address birthday]).each do |field|
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

    self
  end

  class << self
    def find(id)
      customer = API.retrieve customer_id: id
      raise KeyError, "no customer found for id `#{id}'" unless customer.success?

      new customer.data, &:persist!
    end

    def all
      cursor = nil
      customers = []

      loop do
        list = API.search body: {cursor: cursor}
        customers += list.data.map do |customer|
          new customer, &:persist!
        end

        return customers unless cursor
      end
    end

    def create(attributes = OpenStruct.new)
      yield attributes if block_given?
      API.create body: attributes.to_h.symbolize_keys
    end

    def update(id, attributes)
      API.update customer_id: id, body: attributes.to_h.symbolize_keys
    end

    def delete(id)
      API.delete customer_id: id
    end
    alias destroy delete

    def each
      all.each { |customer| yield customer }
    end
  end

  def update(attributes)
    response = self.class.update id, attributes
    raise response.errors.inspect if response.error?

    self.attributes = response.data
    persist!

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

    self.attributes = response.data
    persist!

    self
  end

  def save!
    # Update
    return update changes.transform_values(&:last) if @persisted

    # Create
    response = self.class.create changes.transform_values(&:last)
    raise response.errors.inspect if response.error?

    self.attributes = response.data
    persist!

    self
  end

  def persisted?
    @persisted
  end

  def persist!
    changes_applied
    @persisted = true
  end

  def pretty_print(pp)
    pp.object_address_group self do
      pp.breakable

      attributes.symbolize_keys.slice(*self.class::TRAITS).each do |field, value|
        pp.text "#{field}: #{value.inspect}"
        pp.comma_breakable
      end

      *head, tail = attributes.symbolize_keys.slice(*self.class::FIELDS).to_a

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
