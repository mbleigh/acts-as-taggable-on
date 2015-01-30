if using_postgresql? and postgresql_support_json?
  class TaggableNamespacedModelWithJson < ActiveRecord::Base
    acts_as_taggable namespace: :nspaced
    acts_as_taggable_on :skills, namespace: :nspaced
  end
end