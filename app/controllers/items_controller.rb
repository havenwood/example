class ItemsController < ApplicationController
  include Pagy::Backend

  PER_PAGE = 15

  def index
    page = Integer params.fetch :page, 1

    @items = Item.paginate page: page, per_page: PER_PAGE
    @pagy = Pagy::Countless.new page: page, items: PER_PAGE
    @pagy.finalize @items.size.succ
  end

  def show
    @item = Item.find params[:id]
  end

  def destroy
    response = Item.delete params[:id]
    Item.list.flush_cache if response.success?

    respond_to do |format|
      format.html { redirect_to items_url, notice: 'Item was successfully deleted.' }
      format.json { head :no_content }
    end
  end
end
