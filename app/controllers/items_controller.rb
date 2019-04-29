# frozen_string_literal: true

class ItemsController < ApplicationController
  include Pagy::Backend

  PER_PAGE = 15

  def index
    page = Integer params.fetch :page, 1

    @pagy, @items = pagy_array Item.all
  end

  def show
    @item = Item.find params[:id]
  end

  def destroy
    response = Item.delete params[:id]

    respond_to do |format|
      format.html { redirect_to items_url, notice: 'Item was successfully deleted.' }
      format.json { head :no_content }
    end
  end
end
