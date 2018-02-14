class GpTemplate::Item < ApplicationRecord
  include Sys::Model::Base
  include Cms::Model::Site
  include Cms::Model::Auth::Content

  default_scope { order("#{self.table_name}.sort_no IS NULL, #{self.table_name}.sort_no") }

  attribute :sort_no, :integer, default: 10

  enum_ish :state, [:public, :closed], default: :public, predicate: true
  enum_ish :item_type, [:text_field, :text_area, :rich_text,
                        :select, :radio_button, :attachment_file], default: :text_field

  belongs_to :template
  validates :template_id, presence: true

  delegate :content, to: :template

  validates :state, presence: true

  validates :title, presence: true
  validates :name, presence: true, uniqueness: { scope: :template_id, case_sensitive: false },
                   format: { with: /\A[-\w]*\z/ }
  validates :item_type, presence: true

  define_site_scope :template

  scope :public_state, -> { where(state: 'public') }

  def item_options_for_select
    item_options.split(/[\r\n]+/)
  end
end
