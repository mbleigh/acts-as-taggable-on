class TaggableModel < ActiveRecord::Base
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
  has_many :untaggable_models
end


class Tag < ActsAsTaggableOn::Tag
end

class Tagging < ActsAsTaggableOn::Tagging
end

class Group < Tag

end


class TaggableModelCustomized < ActiveRecord::Base
  set_tagging_class "Tagging"
  set_tag_class "Tag"

  acts_as_taggable
  acts_as_taggable_on :languages, :skills, :needs, :offerings

  acts_as_taggable_on(:groups => "Group")
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

class TaggableUser < ActiveRecord::Base
  acts_as_tagger
end

class InheritingTaggableUser < TaggableUser
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
