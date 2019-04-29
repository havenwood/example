# frozen_string_literal: true

class Item
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

  API = Square::Client.new(access_token: ENV['SQUARE_TOKEN']).catalog

  IMMUTABLE_FIELDS = %i[type id updated_at is_deleted present_at_all_locations item_data].freeze
  FIELDS = %i[version].freeze

  attribute :type, :string
  attribute :id, :string
  attribute :updated_at, :datetime
  attribute :is_deleted, :boolean
  attribute :present_at_all_locations, :boolean
  attribute :item_data

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
      catalog = API.retrieve_catalog_object object_id: id
      raise KeyError, "no item found for id `#{id}'" unless catalog.success?

      new(catalog.data['object']).tap do |item|
        item.persisted = true
        item.changes_applied
      end
    end

    def all
      list = API.list_catalog
      items = list.data['objects'].map { |item| new item }

      while cursor = list.cursor
        list = API.list_catalog cursor: cursor
        items += list.data['objects'].map { |item| new item }
      end

      items
    end

    def create(attributes = OpenStruct.new)
      yield attributes if block_given?
      API.create idempotency_key: SecureRandom.uuid, body: attributes.to_h.symbolize_keys
    end

    def update(id, attributes)
      API.update object_id: id, body: attributes.to_h.symbolize_keys
    end

    def delete(id)
      API.delete object_id: id
    end
    alias destroy delete

    def each
      all.each { |customer| yield customer }
    end
  end

  def update(attributes)
    response = self.class.update id, attributes
    raise response.errors.inspect if response.error?

    self.attributes = response.data['object']
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
             rescue StandardError
      end
    end

    # Create
    response = self.class.create changes.transform_values(&:last)
    return false if response.error?

    @persisted = true
    self.attributes = response.data['object']
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
    self.attributes = response.data['object']
    changes_applied

    self
  end

  def persisted?
    @persisted
  end

  def pretty_print(pp)
    pp.object_address_group self do
      pp.breakable

      attributes.symbolize_keys.slice(*self.class::IMMUTABLE_FIELDS).each do |field, value|
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

    "#<#{self.class}:#{format '%#018x', object_id << 1} #{attrs}>"
  end
end
