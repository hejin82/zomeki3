require 'will_paginate/array'
class GpArticle::Public::Node::DocsController < Cms::Controller::Public::Base
  include GpArticle::Controller::Public::Scoping
  include GpArticle::Controller::Feed

  skip_after_action :render_public_layout, only: [:file_content, :qrcode]

  def pre_dispatch
    @content = GpArticle::Content::Doc.find_by(id: Page.current_node.content.id)
    return http_error(404) unless @content
  end

  def index
    @docs = @content.docs_for_list.order(@content.docs_order_as_hash)
    if params[:format].in?(['rss', 'atom'])
      @docs = @docs.date_after(@content.docs_order_column, @content.feed_docs_period.to_i.days.ago.beginning_of_day) if @content.feed_docs_period.present?
      @docs = @docs.paginate(page: params[:page], per_page: @content.feed_docs_number)
      return render_feed(@docs)
    end
    @docs = GpArticle::DocsPreloader.new(@docs).preload(:public_node_ancestors)

    if @content.simple_pagination?
      @docs = @docs.date_after(@content.docs_order_column, @content.doc_list_period.to_i.months.ago.beginning_of_day) if @content.doc_list_period.present?
      @docs = @docs.paginate(page: params[:page], per_page: @content.doc_list_number)
      return http_error(404) if @docs.current_page > @docs.total_pages
    else
      @docs = @docs.date_paginate(@content.docs_order_column, @content.docs_order_direction,
                                  scope: @content.doc_list_pagination,
                                  date: current_date)
      return http_error(404) if params[:date].present? && @docs.blank?
    end

    @items = @docs.group_by { |doc| doc[@content.docs_order_column].try(:strftime, @content.date_style) }
  end

  def show
    params[:filename_base], params[:format] = 'index', 'html' unless params[:filename_base]

    @item = public_or_preview_doc(id: params[:id], name: params[:name])
    return http_error(404) if @item.nil? || @item.filename_base != params[:filename_base]
    return http_error(404) if @item.external_link?

    Page.current_item = @item
    Page.title = if request.mobile?
                   @item.mobile_title.presence || @item.title
                 else
                   @item.title
                 end
  end

  def file_content
    @doc = public_or_preview_doc(id: params[:id], name: params[:name])
    return http_error(404) unless @doc

    params[:file] = File.basename(params[:path])
    params[:type] = :thumb if params[:path] =~ /(\/|^)thumb\//

    file = @doc.files.find_by!(name: "#{params[:file]}.#{params[:format]}")
    send_file file.upload_path(type: params[:type]), filename: file.name
  end

  def qrcode
    @doc = public_or_preview_doc(id: params[:id], name: params[:name])
    return http_error(404) unless @doc
    return http_error(404) unless @doc.qrcode_visible?

    qrcode = Util::Qrcode.create(@doc.public_full_uri)
    return http_error(404) unless qrcode

    send_data qrcode, filename: 'qrcode.png'
  end

  private

  def set_gp_article_public_scoping
    if Core.mode == 'preview' && params[:action].in?(%w(show file_content qrcode))
      yield
    else
      super
    end
  end

  def current_date
    if params[:date].present?
      params[:date].size == 6 ? "#{params[:date]}01".to_date : params[:date].to_date
    else
      nil
    end
  end

  def public_or_preview_doc(id: nil, name: nil)
    if id
      @content.docs.find_by(id: id)
    elsif name
      @content.docs.order(:id).find_by(name: name)
    end
  end
end
