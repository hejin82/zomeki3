class Organization::Public::Piece::OutlinesController < Organization::Public::PieceController
  def pre_dispatch
    @piece = Organization::Piece::Outline.where(id: Page.current_piece.id).first
    return render plain: '' unless @piece

    @item = Page.current_item
  end

  def index
    render plain: (@item.kind_of?(Organization::Group) ? @item.outline : '')
  end
end
