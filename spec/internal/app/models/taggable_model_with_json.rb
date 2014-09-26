if using_postgresql? and postgresql_support_json?
  class TaggableModelWithJson < ActiveRecord::Base
    acts_as_taggable
    acts_as_taggable_on :skills
  end
end