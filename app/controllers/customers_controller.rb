class CustomersController < ApplicationController
  include Pagy::Backend

  PER_PAGE = 8

  def index
    page = Integer params.fetch :page, 1

    @customers = Customer.list.paginate page: page, per_page: PER_PAGE
    @pagy = Pagy::Countless.new page: page, items: PER_PAGE
    @pagy.finalize @customers.size.succ
  end

  def show
    @customer = Customer.retrieve(customer_id: params[:id]).to_h
  end
end
