class Tagging < ActiveRecord::Base
  include ActsAsTaggableOn::ActiveRecord::Backports
end