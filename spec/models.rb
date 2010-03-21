class TaggableModel < ActiveRecord::Base
  acts_as_taggable
  acts_as_taggable_on :languages
  acts_as_taggable_on :skills
  acts_as_taggable_on :needs, :offerings
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

class UntaggableModel < ActiveRecord::Base
end

if ActiveRecord::VERSION::MAJOR < 3
  [TaggableModel, OtherTaggableModel, InheritingTaggableModel,
   AlteredInheritingTaggableModel, TaggableUser, UntaggableModel].each do |klass|
    klass.send(:include, ActsAsTaggableOn::ActiveRecord::Backports)
  end
end