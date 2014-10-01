class TaggableNamespacedModel < ActiveRecord::Base
  acts_as_taggable namespace: :nspaced
  acts_as_taggable_on :languages, namespace: :nspaced
  acts_as_taggable_on :skills, namespace: :nspaced
  acts_as_taggable_on :needs, :offerings, namespace: :nspaced

  has_many :untaggable_namespaced_models
  alias_method :untaggable_models, :untaggable_namespaced_models

  attr_reader :tag_list_submethod_called
  def tag_list=(v)
    @tag_list_submethod_called = true
    super
  end
end
