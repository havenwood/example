require 'will_paginate/collection'

class CustomerController < ApplicationController
  SQUARE = Square.new

  def list
    @customers_list ||= SQUARE.customers.list

    page = params.fetch(:page, 1).to_i
    total = 5001

    @customers = WillPaginate::Collection.create(page, @customers_list.per_page, total) do |pager|
      pager.replace @customers_list.paginate page: page
    end
  end
end
