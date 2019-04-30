# frozen_string_literal: true

require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  include ActiveModel::Lint::Tests

  setup do
    @model = Item.new
  end
end
