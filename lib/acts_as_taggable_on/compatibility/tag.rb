class Tag < ActiveRecord::Base
  include ActsAsTaggableOn::ActiveRecord::Backports
end