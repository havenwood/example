class CustomerController < ApplicationController
  SQUARE = Square.new
  CUSTOMER_LIST = SQUARE.customers.list

  def list
    page = params.fetch(:page, 1).to_i

    @customers_list.paginate page: page
  end
end
