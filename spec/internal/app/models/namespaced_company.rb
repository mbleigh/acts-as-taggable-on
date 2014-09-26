class NamespacedCompany < ActiveRecord::Base
  acts_as_taggable_on :locations, :markets, namespace: :nspaced

  has_many :markets, through: :market_taggings, source: :tag, class_name: :namespaced_market

  private

  def find_or_create_tags_from_list_with_context(tag_list, context)
    if context.to_sym == :markets
      NamespacedMarket.find_or_create_all_with_like_by_name(tag_list)
    else
      super
    end
  end
end