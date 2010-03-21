module ActsAsTaggableOn::Taggable
  module Ownership
    def self.included(base)
      include InstanceMethods
      base.extend ClassMethods
    end
    
    module ClassMethods
    end
    
    module InstanceMethods
    end
  end
end