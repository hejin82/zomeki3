class GpArticle::Public::Piece::DocsController < Sys::Controller::Public::Base
  include GpArticle::Controller::Public::Scoping

  def pre_dispatch
    @piece = GpArticle::Piece::Doc.find_by(id: Page.current_piece.id)
    render plain: '' unless @piece

    @item = Page.current_item
  end

  def index
    @docs = @piece.content.docs_for_list
                  .limit(@piece.docs_number)
                  .order(@piece.docs_order_as_sql)

    @docs = GpArticle::DocsPreloader.new(@docs).preload(:public_node_ancestors)
  end
end
