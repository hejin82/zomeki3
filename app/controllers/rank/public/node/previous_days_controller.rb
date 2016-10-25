class Rank::Public::Node::PreviousDaysController < Cms::Controller::Public::Base
  include Rank::Controller::Rank

  def pre_dispatch
    @node = Page.current_node
    @content = Rank::Content::Rank.find_by(id: Page.current_node.content.id)
    return http_error(404) unless @content
  end

  def index
    @term   = 'previous_days'
    @target = 'pageviews'
    @ranks  = rank_datas(@content, @term, @target, 20)
    return http_error(404) if @ranks.blank?
  end
end
