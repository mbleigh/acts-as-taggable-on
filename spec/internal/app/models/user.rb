class User < ActiveRecord::Base
  acts_as_tagger
end

class Student < User
end
