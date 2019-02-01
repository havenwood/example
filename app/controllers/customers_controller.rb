class CustomersController < ApplicationController
  include Pagy::Backend

  PER_PAGE = 25

  def index
    page = Integer params.fetch :page, 1

    @customers = Customer.list.paginate page: page, per_page: PER_PAGE
    @pagy = Pagy::Countless.new page: page, items: PER_PAGE
    @pagy.finalize @customers.size.succ
  end

  def show
    @customer = Customer.find params[:id]
  end

  def new
    @customer = Customer.new
  end

  def edit
    @customer = Customer.find params[:id]
  end

  def create
  end

  def update
  end

  def destroy
    response = Customer.new.delete customer_id: params[:id]
    Customer.list.flush_cache if response.success?

    respond_to do |format|
      format.html { redirect_to customers_url, notice: 'Customer was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def customer_params
    params.require(:customer).permit(Customer::FIELDS)
  end
end
