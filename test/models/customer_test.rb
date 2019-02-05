
require 'test_helper'

class CustomerTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  setup do
    @model = Customer.new
  end
end
