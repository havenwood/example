# frozen_string_literal: true

class CustomersController < ApplicationController
  include Pagy::Backend

  PER_PAGE = 15

  def index
    page = Integer params.fetch :page, 1

    @pagy, @customers = pagy_array Customer.all
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
    response = Customer.create customer_params

    respond_to do |format|
      if response.success?
        @customer = Customer.find response.data['id']

        format.html { redirect_to @customer, notice: 'Customer was successfully created.' }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html do
          flash.now[:errors] = response.errors
          render :new
        end
        format.json { render json: response.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @customer = Customer.find params[:id]
    response = Customer.update @customer.id, customer_params

    respond_to do |format|
      if response.success?
        format.html { redirect_to @customer, notice: 'Customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html do
          flash.now[:errors] = response.errors
          render :edit
        end
        format.json { render json: response.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    response = Customer.delete params[:id]

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
