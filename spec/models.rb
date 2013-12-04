class TaggableModel < ActiveRecord::Base
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
  has_many :untaggable_models

  attr_reader :tag_list_submethod_called
  def tag_list=v
    @tag_list_submethod_called = true
    super
  end
end

class CachedModel < ActiveRecord::Base
  acts_as_taggable
end

class OtherCachedModel < ActiveRecord::Base
  acts_as_taggable_on :languages, :statuses, :glasses
end

class OtherTaggableModel < ActiveRecord::Base
  acts_as_taggable_on :tags, :languages
  acts_as_taggable_on :needs, :offerings
end

class InheritingTaggableModel < TaggableModel
end

class AlteredInheritingTaggableModel < TaggableModel
  acts_as_taggable_on :parts
end

class User < ActiveRecord::Base
  acts_as_tagger
end

class Student < User
end

class UntaggableModel < ActiveRecord::Base
  belongs_to :taggable_model
end

class NonStandardIdTaggableModel < ActiveRecord::Base
  primary_key = "an_id"
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
  has_many :untaggable_models
end

class OrderedTaggableModel < ActiveRecord::Base
  acts_as_ordered_taggable
  acts_as_ordered_taggable_on :colours
end
